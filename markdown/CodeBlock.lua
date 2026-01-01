function CodeBlock(el)
  local is_haskell = false
  local is_ghci = false

  -- 1. Detect Haskell/GHCi classes
  for _, class in ipairs(el.classes) do
    if class:match("ghci") then
      is_haskell = true; is_ghci = true
    elseif class:match("^haskell") then
      is_haskell = true
    end
  end

  if is_haskell and is_ghci then
    -- We will build the HTML manually, line by line
    local final_html_lines = {}
    
    -- Helper to escape HTML for the output lines
    local function escape_html(s)
      return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    end

    -- Split the text into lines and process them
    for line in el.text:gmatch("([^\r\n]*)\r?\n?") do
      -- gmatch returns an empty string at the very end, ignore it if we already processed everything
      if line == "" and #final_html_lines > 0 and final_html_lines[#final_html_lines]:match("</div>$") then 
        -- This logic handles the loop edge case, but simpler is:
      end
      if line == "" then goto continue end 

      if line:match("^ghci>") then
        -- === CASE 1: PROMPT LINE ===
        -- Isolate the code part (remove 'ghci> ')
        local code_part = line:gsub("^ghci>%s?", "")
        
        -- Run syntax highlighter ONLY on the code part
        -- We wrap it in a dummy block to feed it to pandoc
        local dummy_block = "```haskell\n" .. code_part .. "\n```"
        local highlighted_html = pandoc.pipe("pandoc", {"-f", "markdown", "-t", "html", "--highlight-style=tango"}, dummy_block)
        
        -- Pandoc returns a full <div class="sourceCode"><pre>... result. 
        -- We need to strip those wrappers to inline it.
        -- Extract just the inner HTML of the <code> tag or the span content
        local inner_html = highlighted_html:match('<code[^>]*>(.*)</code>') or highlighted_html:match('<pre[^>]*>(.*)</pre>')
        
        -- If match failed (paranoid check), fall back to escaped text
        if not inner_html then inner_html = escape_html(code_part) end

        -- Reassemble: Custom Prompt Span + Highlighted Code
        local formatted_line = '<span class="ghci-prompt">ghci&gt; </span>' .. inner_html
        table.insert(final_html_lines, formatted_line)
        
      else
        -- === CASE 2: OUTPUT/ERROR LINE ===
        -- Just escape it. Do NOT highlight it.
        -- You can add a class here if you want output to be a specific color (e.g. grey)
        local formatted_line = '<span class="ghci-output">' .. escape_html(line) .. '</span>'
        table.insert(final_html_lines, formatted_line)
      end
      
      ::continue::
    end

    -- Wrap the whole thing in a block that looks like the others
    local final_block = '<div class="sourceCode"><pre class="sourceCode haskell"><code class="sourceCode haskell">' 
                        .. table.concat(final_html_lines, "\n") 
                        .. '</code></pre></div>'
    
    return pandoc.RawBlock("html", final_block)
  end
  
  -- Fallback for standard Haskell blocks (non-ghci)
  if is_haskell then
    el.classes = {'haskell'}
    return el
  end
  
  return nil
end