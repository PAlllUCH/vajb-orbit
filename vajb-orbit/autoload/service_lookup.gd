class_name ServiceLookup
extends RefCounted
## One root-node lookup for the four node autoloads (CODE_AUDIT 2026-10-19, P1
## item 7). Autoload names are not resolvable identifiers until the project
## patch lands, so a service is looked up by name off the tree root; each
## autoload keeps its small `_service` door delegating here.
##
## Not an autoload: nothing in `project.godot` names this file.
##
## Reversal: copy the two-line lookup back into the autoload that needs it.

static func find(node: Node, service_name: StringName) -> Node:
	if not node.is_inside_tree():
		return null
	return node.get_tree().root.get_node_or_null(NodePath(service_name))
