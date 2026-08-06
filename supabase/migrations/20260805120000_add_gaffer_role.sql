-- Add gaffer/department-lead role, per the role-based collaboration design handoff
-- (Aug 2026). Requests lighting & grip gear into a package without seeing camera
-- budget — needs a seat in production_role plus a department scope, since a
-- department-lead's authority is scoped to one department, not the whole package.

alter type production_role add value 'gaffer';

-- department scope for department-lead memberships (e.g. 'lighting_grip').
-- Null for dp/coordinator/producer, whose authority isn't department-scoped.
alter table production_members add column department text;
