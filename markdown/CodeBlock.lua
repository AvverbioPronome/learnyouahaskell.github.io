function CodeBlock(el)
    -- 1. Check if we need to run
    local is_haskell = false
    local is_ghci = false
    for _, class in ipairs(el.classes) do
        if class:match("ghci") then
            is_haskell = true;
            is_ghci = true
        elseif class:match("^haskell") then
            is_haskell = true
        end
    end

    if is_haskell and not is_ghci then
        el.classes = {"haskell"}
        return el
    elseif not (is_ghci and is_haskell) then 
        return nil
    end

    -- 2. Define "Noise Patterns" (Lines that should NEVER be highlighted)
    local noise_patterns = {
        "^<interactive>:", -- Error locations
        "^%s*•", -- Error bullet points (GHC 9+)
        "^%s*In the", -- Error context
        "^%[%d+ of %d+%]", -- Compiler progress [1 of 1]
        "^Ok,.*loaded%.$", -- Loader success
        "^Failed,.*loaded%.$" -- Loader failure
    }

    local function is_noise(line)
        for _, pattern in ipairs(noise_patterns) do
            if line:match(pattern) then return true end
        end
        return false
    end

    -- 3. Prepare the Batch
    local input_lines = {}
    local output_map = {}
    local prompt_indices = {}

    local i = 1
    for line in el.text:gmatch("([^\r\n]*)\r?\n?") do
        if line ~= "" then
            if line:match("^ghci>") then
                -- === PROMPT ===
                -- Strip prompt, keep code. This will be highlighted.
                input_lines[i] = line:gsub("^ghci>%s?", "")
                prompt_indices[i] = true

            elseif not is_noise(line) then
                -- === VALUE (e.g. "18" or "[1,2]") ===
                -- It's not a prompt, but it looks like valid data. 
                -- Let's HIGHLIGHT IT as if it were code!
                input_lines[i] = line
                prompt_indices[i] = false

            else
                -- === NOISE (Logs/Errors) ===
                -- Mask it so the highlighter ignores it completely.
                local token = "___GHCI_NOISE_" .. i .. "___"
                output_map[token] = line
                input_lines[i] = "-- " .. token -- comment it out for the highlighter
                prompt_indices[i] = false
            end
            i = i + 1
        end
    end

    -- 4. Highlight the Batch
    --print(table.concat(input_lines, "\n"))
    -- print(table.concat(input_lines, "\n"))
    local batch_code = table.concat(input_lines, "\n")
    local batch_block = pandoc.CodeBlock(batch_code, pandoc.Attr("", {"haskell"}))
    local doc = pandoc.Pandoc({ batch_block })

    local html = pandoc.write(doc, "html")
    --print(html)
    -- 5. Clean and Unmask
    local inner_html = html:match('<code[^>]*>(.*)</code>') or
                           html:match('<pre[^>]*>(.*)</pre>') or html

    local final_lines = {}
    local line_idx = 1

    for html_line in inner_html:gmatch("([^\r\n]*)\r?\n?") do
        if html_line ~= "" then
            if prompt_indices[line_idx] then
                -- Prompt Line
                table.insert(final_lines,'<span class="ghci-prompt">ghci&gt; </span>' .. html_line)
            else
                -- Output Line. Check if it was masked.
                local token = "___GHCI_NOISE_" .. line_idx .. "___"
                local original_text = output_map[token]

                if original_text then
                    -- It was Noise. Restore original text, plain and uncolored.
                    local escaped = original_text:gsub("&", "&amp;"):gsub("<","&lt;"):gsub(">", "&gt;")
                    table.insert(final_lines, '<span class="ghci-output">' .. escaped .. '</span>')
                else
                    -- It was a Value. Keep the highlighting Pandoc gave it!
                    -- (Optional: Wrap in a span if you want to make values bold or something)
                    table.insert(final_lines, '<span class="ghci-value">' .. html_line .. '</span>')
                end
            end
            line_idx = line_idx + 1
        end
    end

    local final_block =
        '<div class="sourceCode"><pre class="sourceCode haskell"><code class="sourceCode haskell">' ..
            table.concat(final_lines, "\n") .. '</code></pre></div>'
    --print(table.concat(final_lines), "\n")
    return pandoc.RawBlock("html", final_block)
end