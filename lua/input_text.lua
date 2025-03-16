local translation = require("trans-all")

local function trans(text)
    local result
    
    if translation.config.default_api == "google" then
        result = translation.google(text)
    elseif translation.config.default_api == "deepl" then
        result = translation.deepl(text)
    elseif translation.config.default_api == "microsoft" then
        result = translation.microsoft(text)
    elseif translation.config.default_api == "deeplx" then
        result = translation.deeplx(text)
    elseif translation.config.default_api == "niutrans" then
        result = translation.niutrans(text)
    else
        result = translation.google(text)
    end
    
    return result
end

local function is_chinese_character(char)
    local code = utf8.codepoint(char)
    return code >= 0x4E00 and code <= 0x9FFF
end

local function filter(input, env)
    local input_text = env.engine.context.input

    if input_text:sub(-2) == "''" then
        local raw_input = {}
        local count = 0
        for cand in input:iter() do
            if not cand.text then
                goto continue
            end
            
            local first_char
            local success = pcall(function()
                first_char = utf8.char(utf8.codepoint(cand.text))
            end)
            
            if not success then
                goto continue
            end
            
            if is_chinese_character(first_char) then
                if count < 6 then
                    count = count + 1
                    table.insert(raw_input, cand.text)
                else
                    break
                end
            end
            
            ::continue::
        end
        
        if #raw_input == 0 then
            for cand in input:iter() do
                yield(cand)
            end
            return
        end
        
        local translated_text = trans(raw_input[1])
        
        if not translated_text then
            yield(Candidate("error", 0, #input_text, "[翻译失败]", "请检查网络或API配置"))
            
            for cand in input:iter() do
                yield(cand)
            end
            return
        end
        
        yield(Candidate("translation", 0, #input_text, translated_text, "[译] " .. raw_input[1]))
        
        for cand in input:iter() do
            yield(cand)
        end
    else
        for cand in input:iter() do
            yield(cand)
        end
    end
end

return filter