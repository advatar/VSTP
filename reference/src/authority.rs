use crate::model::{Authority, Permission};

fn contained(child: &[Permission], parent: &[Permission]) -> bool {
    child.iter().all(|permission| parent.contains(permission))
}

pub fn effective_scope(authority: &Authority, actor: &str) -> Result<Vec<Permission>, String> {
    let mut holder = authority.root_principal.as_str();
    let mut scope = authority.root_scope.clone();
    for delegation in &authority.delegations {
        if delegation.delegator != holder {
            return Err("authority-chain-broken".into());
        }
        if !contained(&delegation.scope, &scope) {
            return Err("authority-amplification".into());
        }
        holder = &delegation.delegate;
        scope = delegation.scope.clone();
    }
    if holder != actor {
        return Err("authority-actor-mismatch".into());
    }
    Ok(scope)
}

pub fn covers(scope: &[Permission], resource: &str, structural_class: &str) -> bool {
    scope
        .iter()
        .any(|p| p.resource == resource && p.structural_class == structural_class)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::Delegation;

    fn p(resource: &str) -> Permission {
        Permission {
            resource: resource.into(),
            structural_class: "update".into(),
        }
    }

    #[test]
    fn rejects_amplification() {
        let authority = Authority {
            root_principal: "root".into(),
            root_scope: vec![p("a")],
            delegations: vec![Delegation {
                delegator: "root".into(),
                delegate: "actor".into(),
                scope: vec![p("a"), p("b")],
            }],
        };
        assert_eq!(
            effective_scope(&authority, "actor"),
            Err("authority-amplification".into())
        );
    }
}
