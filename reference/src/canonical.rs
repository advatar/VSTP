use serde::Serialize;
use serde_json::Value;

/// Example Profile 00 canonical JSON: UTF-8, no whitespace, object keys sorted
/// by Unicode code point, integers only. Strings use serde_json's JSON escaping.
pub fn to_vec<T: Serialize>(value: &T) -> Result<Vec<u8>, String> {
    let value = serde_json::to_value(value).map_err(|e| e.to_string())?;
    let mut out = Vec::new();
    write_value(&value, &mut out)?;
    Ok(out)
}

fn write_value(value: &Value, out: &mut Vec<u8>) -> Result<(), String> {
    match value {
        Value::Null => out.extend_from_slice(b"null"),
        Value::Bool(v) => out.extend_from_slice(if *v { b"true" } else { b"false" }),
        Value::Number(v) if v.is_i64() || v.is_u64() => {
            out.extend_from_slice(v.to_string().as_bytes())
        }
        Value::Number(_) => return Err("floating-point numbers are not canonical".into()),
        Value::String(v) => out.extend_from_slice(
            serde_json::to_string(v)
                .map_err(|e| e.to_string())?
                .as_bytes(),
        ),
        Value::Array(values) => {
            out.push(b'[');
            for (i, item) in values.iter().enumerate() {
                if i != 0 {
                    out.push(b',');
                }
                write_value(item, out)?;
            }
            out.push(b']');
        }
        Value::Object(values) => {
            out.push(b'{');
            let mut entries: Vec<_> = values.iter().collect();
            entries.sort_unstable_by_key(|(key, _)| *key);
            for (i, (key, item)) in entries.into_iter().enumerate() {
                if i != 0 {
                    out.push(b',');
                }
                write_value(&Value::String(key.clone()), out)?;
                out.push(b':');
                write_value(item, out)?;
            }
            out.push(b'}');
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn sorts_keys_and_removes_whitespace() {
        assert_eq!(
            to_vec(&json!({"z": 1, "a": [true, "x"]})).unwrap(),
            b"{\"a\":[true,\"x\"],\"z\":1}"
        );
    }
}
