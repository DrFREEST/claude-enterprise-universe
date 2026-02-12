/**
 * universe-loader.mjs - Enterprise Agent Universe 설정 로더
 *
 * config/universe.json을 로드하고
 * 미션에 맞는 부서/에이전트 매핑을 반환
 */

import { readFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PLUGIN_ROOT = resolve(__dirname, '..');
const CONFIG_PATH = resolve(PLUGIN_ROOT, 'config', 'universe.json');

let _cachedConfig = null;

// =============================================================================
// 설정 로드
// =============================================================================

/**
 * Enterprise Universe 설정 로드
 * @returns {Object} 전체 설정 객체
 */
export function loadUniverseConfig() {
  if (_cachedConfig) return _cachedConfig;

  if (!existsSync(CONFIG_PATH)) {
    throw new Error(`Enterprise Universe 설정 파일 없음: ${CONFIG_PATH}`);
  }

  const raw = readFileSync(CONFIG_PATH, 'utf-8');
  _cachedConfig = JSON.parse(raw);
  return _cachedConfig;
}

/**
 * 설정 캐시 초기화
 */
export function resetConfigCache() {
  _cachedConfig = null;
}

// =============================================================================
// 부서 조회
// =============================================================================

/**
 * 전체 부서 목록 반환
 * @returns {Array<{id, name_ko, name_en, tier, memberCount}>}
 */
export function listDepartments() {
  const config = loadUniverseConfig();
  return Object.entries(config.departments).map(([id, dept]) => ({
    id,
    name_ko: dept.name_ko,
    name_en: dept.name_en,
    tier: dept.tier,
    memberCount: Object.keys(dept.members).length,
    alwaysActive: dept.always_active || false,
  }));
}

/**
 * 특정 부서 상세 정보 반환
 * @param {string} deptId - 부서 ID (예: "backend_dev")
 * @returns {Object|null}
 */
export function getDepartment(deptId) {
  const config = loadUniverseConfig();
  return config.departments[deptId] || null;
}

/**
 * 부서의 멤버 목록 반환
 * @param {string} deptId - 부서 ID
 * @returns {Array<{id, title_ko, agent_type, mcp_tool, model}>}
 */
export function getDepartmentMembers(deptId) {
  const dept = getDepartment(deptId);
  if (!dept) return [];

  return Object.entries(dept.members).map(([id, member]) => ({
    id,
    title_ko: member.title_ko,
    agent_type: member.agent_type,
    subagent_type: member.subagent_type,
    mcp_tool: member.mcp_tool,
    mcp_role: member.mcp_role || null,
    model: member.model,
    responsibilities: member.responsibilities,
  }));
}

// =============================================================================
// 미션 매칭
// =============================================================================

/**
 * 미션 템플릿 목록 반환
 * @returns {Array<{id, name_ko, departments, workflow}>}
 */
export function listMissionTemplates() {
  const config = loadUniverseConfig();
  return Object.entries(config.mission_templates).map(([id, tmpl]) => ({
    id,
    name_ko: tmpl.name_ko,
    departments: tmpl.activate,
    workflow: tmpl.workflow,
  }));
}

/**
 * 미션 템플릿으로 활성화할 에이전트 목록 반환
 * @param {string} templateId - 미션 템플릿 ID
 * @returns {Object} { departments, agents, mcpAgents, taskAgents, estimatedCost }
 */
export function resolveTemplate(templateId) {
  const config = loadUniverseConfig();
  const template = config.mission_templates[templateId];

  if (!template) return null;

  const departments = [];
  const mcpAgents = [];
  const taskAgents = [];

  for (const deptId of template.activate) {
    const dept = config.departments[deptId];
    if (!dept) continue;

    departments.push({
      id: deptId,
      name_ko: dept.name_ko,
      tier: dept.tier,
    });

    for (const [memberId, member] of Object.entries(dept.members)) {
      const agentInfo = {
        department: deptId,
        memberId,
        title_ko: member.title_ko,
        agent_type: member.agent_type,
        model: member.model,
      };

      if (member.mcp_tool) {
        mcpAgents.push({
          ...agentInfo,
          mcp_tool: member.mcp_tool,
          mcp_role: member.mcp_role,
        });
      } else {
        taskAgents.push({
          ...agentInfo,
          subagent_type: member.subagent_type,
        });
      }
    }
  }

  // 비용 추정 (opus=3, sonnet=1, haiku=0.3)
  const costMap = { opus: 3, sonnet: 1, haiku: 0.3 };
  const totalCost = [...mcpAgents, ...taskAgents].reduce(
    (sum, a) => sum + (costMap[a.model] || 1),
    0
  );

  let estimatedCost = 'LOW';
  if (totalCost > 20) estimatedCost = 'VERY HIGH';
  else if (totalCost > 12) estimatedCost = 'HIGH';
  else if (totalCost > 6) estimatedCost = 'MEDIUM';

  return {
    templateId,
    name_ko: template.name_ko,
    workflow: template.workflow,
    departments,
    mcpAgents,
    taskAgents,
    totalAgents: mcpAgents.length + taskAgents.length,
    estimatedCost,
  };
}

// =============================================================================
// 비용 가드
// =============================================================================

/**
 * 활성화 제한 확인
 * @param {number} agentCount - 활성화할 에이전트 수
 * @returns {Object} { allowed, warning, reason }
 */
export function checkActivationLimits(agentCount) {
  const config = loadUniverseConfig();
  const rules = config.activation_rules;

  if (agentCount > rules.cost_guard.hard_limit_agents) {
    return {
      allowed: false,
      warning: true,
      reason: `에이전트 ${agentCount}개 초과 (한도: ${rules.cost_guard.hard_limit_agents}개). 부서를 줄이세요.`,
    };
  }

  if (agentCount > rules.cost_guard.warn_at_agents) {
    return {
      allowed: true,
      warning: true,
      reason: `에이전트 ${agentCount}개 (경고 임계값: ${rules.cost_guard.warn_at_agents}개). 비용에 주의하세요.`,
    };
  }

  return {
    allowed: true,
    warning: false,
    reason: `에이전트 ${agentCount}개 - 정상 범위`,
  };
}

// =============================================================================
// 통계
// =============================================================================

/**
 * 유니버스 전체 통계
 */
export function getUniverseStats() {
  const config = loadUniverseConfig();
  return {
    ...config.statistics,
    version: config.version,
    totalTemplates: Object.keys(config.mission_templates).length,
  };
}
