import os
import glob
import re

for filepath in glob.glob("crates/vm/src/stdlib/*.rs"):
    with open(filepath, "r") as f:
        content = f.read()

    # 1. Fix E0597 / E0716 by copying func_ref
    # Find `for (nama, func) in` and replace with `for (nama, func_ref) in`
    content = content.replace("for (nama, func) in", "for (nama, func_ref) in")
    # Add `let func_ptr = *func_ref;` inside the loop body
    content = re.sub(
        r"(for \(nama, func_ref\) in [^\{]+\{)",
        r"\1\n        let func_ptr = *func_ref;",
        content
    )

    # 2. Fix unsafe transmute
    # `unsafe { std::mem::transmute( move |ctx...| { ... } ) }`
    content = re.sub(
        r"unsafe\s*\{\s*std::mem::transmute\(\s*(move\s*\|[^|]+\|\s*->\s*Result<Value,\s*String>\s*\{(?:[^{}]*|\{[^{}]*\})*\})\s*,\s*\)\s*\}",
        r"std::sync::Arc::new(\1)",
        content,
        flags=re.DOTALL
    )

    # But the above regex might fail if there are deeper nested brackets.
    # An easier way: just match `unsafe { std::mem::transmute(` and remove it, then add `std::sync::Arc::new(`, and remove `}, ) }` at the end of the struct.
    # Since they all follow the same format, we can just replace:
    content = re.sub(r"unsafe\s*\{\s*std::mem::transmute\(", r"std::sync::Arc::new(", content)
    content = re.sub(r"\},\s*\)\s*\}", r"})", content)

    # 3. Replace all closures in FungsiBawaanVM with Arc::new
    # Look for `func: |ctx, args| {` -> `func: std::sync::Arc::new(move |ctx: &mut dyn VmContext, args: Vec<Value>| -> Result<Value, String> {`
    # We must also fix the closing bracket `}` -> `})`
    def repl_func(match):
        body = match.group(1)
        # Add std::sync::Arc::new(move |ctx: &mut dyn VmContext, args: Vec<Value>| -> Result<Value, String> 
        # and change the closing `}` to `})`
        # Because we match up to the end of the struct `};`, we can safely replace the last `}`.
        if "std::sync::Arc::new" in body:
            return match.group(0) # Already wrapped
            
        # replace `|ctx, args| {` with `move |ctx...| {`
        body = re.sub(r"\|ctx,\s*args\|\s*\{", r"move |ctx: &mut dyn VmContext, args: Vec<Value>| -> Result<Value, String> {", body, 1)
        
        # replace the last `}` before `};` with `})`
        # body ends with `\n    }`
        body = re.sub(r"\}\s*$", r"})", body)
        
        return "func: std::sync::Arc::new(" + body
        
    # Match `func: ... \n    };` where `...` starts with `|` or a function name.
    # Actually, let's just do the ones that don't start with `std::sync::Arc::new`
    # We can use a simpler approach for the remaining closures:
    content = re.sub(r"func:\s*\|ctx,\s*args\|\s*\{", r"func: std::sync::Arc::new(move |ctx: &mut dyn VmContext, args: Vec<Value>| -> Result<Value, String> {", content)
    
    # And for function names: `func: some_func,`
    content = re.sub(r"func:\s*([a-zA-Z_0-9]+_wrapper),", r"func: std::sync::Arc::new(\1),", content)
    content = re.sub(r"func:\s*([a-zA-Z_0-9]+_func),", r"func: std::sync::Arc::new(\1),", content)
    content = re.sub(r"func:\s*([a-zA-Z_0-9]+),", r"func: std::sync::Arc::new(\1),", content)

    # Finally, fix `match func(` to `match func_ptr(`
    content = content.replace("match func(", "match func_ptr(")

    with open(filepath, "w") as f:
        f.write(content)
