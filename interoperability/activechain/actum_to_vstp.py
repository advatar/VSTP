#!/usr/bin/env python3
"""Map an ActiveChain action export bundle into a VSTP bridge bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any, Dict, List

PROFILE_ID = "urn:vstp:actum:v1"


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def sha384_hex(text: str) -> str:
    return hashlib.sha384(text.encode("utf-8")).hexdigest()


def commitment_from_state(state: Dict[str, Any]) -> Dict[str, Any]:
    commitment = {
        "resource": state.get("resource", ""),
        "representation_profile": state.get("representation_profile", "actum-state:v1"),
        "representation_version": int(state.get("representation_version", 1)),
        "algorithm": state.get("algorithm", "sha-384"),
    }
    digest = state.get("digest")
    if digest is None and "content" in state:
        digest = sha384_hex(str(state["content"]))
    if digest is None:
        raise ValueError(f"state for resource={state.get('resource')} missing digest/content")
    commitment["digest"] = digest
    return commitment


def collect_state_refs(action: Dict[str, Any], modern_key: str, legacy_key: str) -> List[Dict[str, Any]]:
    if modern_key in action:
        values = action[modern_key]
    elif legacy_key in action:
        values = action[legacy_key]
    else:
        raise ValueError(f"missing required state key {modern_key} or fallback {legacy_key}")

    if isinstance(values, dict):
        values = [values]
    elif not isinstance(values, list):
        raise TypeError(f"{modern_key}/{legacy_key} must be an object or array")
    return [commitment_from_state(state) for state in values]


def collect_disclosed_states(
    action: Dict[str, Any], prior_states: List[Dict[str, Any]], resulting_states: List[Dict[str, Any]]
) -> List[Dict[str, str]]:
    explicit = action.get("disclosed_states")
    if isinstance(explicit, list) and explicit:
        return [
            {"resource": str(item.get("resource", "")), "content": str(item.get("content", ""))}
            for item in explicit
            if isinstance(item, dict)
        ]

    raw_states: List[Dict[str, Any]] = []
    for key in ("prior_states", "resulting_states"):
        value = action.get(key)
        if isinstance(value, dict):
            raw_states.append(value)
        elif isinstance(value, list):
            raw_states.extend([state for state in value if isinstance(state, dict)])

    disclosed: List[Dict[str, str]] = []
    for state in raw_states:
        if "resource" in state and "content" in state:
            disclosed.append({"resource": str(state["resource"]), "content": str(state["content"])})

    if disclosed:
        return disclosed

    # Last-resort reconstruction for tooling that only emits commitments.
    seen: set[str] = set()
    result: List[Dict[str, str]] = []
    for state in prior_states:
        resource = state.get("resource")
        if isinstance(resource, str):
            seen.add(resource)
            result.append({"resource": resource, "content": ""})
    for state in resulting_states:
        resource = state.get("resource")
        if isinstance(resource, str) and resource not in seen:
            seen.add(resource)
            result.append({"resource": resource, "content": ""})
    return result


def make_transition_id(payload: Dict[str, Any]) -> str:
    serialized = canonical_json(payload)
    return sha384_hex(serialized)


def merge_scope(action: Dict[str, Any]) -> List[Dict[str, str]]:
    if "scope" in action and action["scope"]:
        return list(action["scope"])
    resource = action.get("resource")
    structural_class = action.get("structural_class", "actum.action")
    if resource:
        return [{"resource": resource, "structural_class": structural_class}]
    return []


def convert(actum: Dict[str, Any], keyring: List[Dict[str, str]]) -> Dict[str, Any]:
    context = actum.get("context", {})
    action = actum.get("action", {})
    principals = actum.get("principals", {})
    authority = actum.get("authority", {})
    evidence = actum.get("evidence", {})

    prior_states = collect_state_refs(action, "prior_states", "prior_state")
    resulting_states = collect_state_refs(action, "resulting_states", "resulting_state")

    transition = {
        "parents": action.get("parents", []),
        "prior_states": prior_states,
        "resulting_states": resulting_states,
        "actor": principals.get("actor", action.get("actor", "")),
        "recorder": principals.get("recorder", action.get("recorder", "")),
        "sequence": int(action.get("sequence", 0)),
        "structural_class": action.get("structural_class", "actum.action"),
    }
    transition["id"] = make_transition_id(transition)
    transition["signature"] = action.get("signature", "")

    bridge = {
        "profile": PROFILE_ID,
        "actum_context": {
            "chain_id": context.get("chain_id"),
            "genesis_commitment": context.get("genesis_commitment"),
            "protocol_revision": context.get("protocol_revision", "v1"),
            "finalized_height": context.get("finalized_height"),
        },
        "keys": keyring,
        "disclosed_states": collect_disclosed_states(action, prior_states, resulting_states),
        "authority": {
            "root_principal": authority.get("root_principal", principals.get("actor", "")),
            "root_scope": authority.get("root_scope", merge_scope(action)),
            "delegations": authority.get("delegations", []),
        },
        "transition": transition,
        "actum_evidence": {
            "policy_decision": evidence.get("policy_decision", {}),
            "approvals": evidence.get("approvals", []),
            "finality": evidence.get("finality", {}),
            "external_evidence": evidence.get("external_evidence", []),
        },
    }
    return bridge


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert ActiveChain action export into a VSTP bridge bundle.")
    parser.add_argument("--input", required=True, type=Path, help="ActiveChain action export JSON")
    parser.add_argument("--keys", required=True, type=Path, help="Keyring JSON used for offline principal resolution")
    parser.add_argument("--output", required=True, type=Path, help="Output VSTP bridge bundle JSON")
    args = parser.parse_args()

    actum = load_json(args.input)
    keys = load_json(args.keys)
    if not isinstance(keys, list):
        raise ValueError("keyring must be a JSON array of { principal, public_key } objects")

    bundle = convert(actum, keys)
    args.output.write_text(canonical_json(bundle) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
