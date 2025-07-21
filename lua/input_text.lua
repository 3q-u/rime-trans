local translation = require("trans-all")

local function trans(text)
    local result
    
    if translation.config.default_api == "google" then
        result = translation.google(text)
    elseif translation.config.default_api == "deepl" then
        result = translation.deepl(text)
    elseif translation.config.default_api == "microsoft" then
        result = translation.microsoft(text)
    elseif translation.config.default_api == "niutrans" then
        result = translation.niutrans(text)
    elseif translation.config.default_api == "youdao" then
        result = translation.youdao(text)
    elseif translation.config.default_api == "baidu" then
        result = translation.baidu(text)
    else
        result = translation.google(text)
    end
    
    return result
end

local function is_chinese_character(char)
    local code = utf8.codepoint(char)
    return code >= 0x4E00 and code <= 0x9FFF
end

-- 处理器模块
local processor = {}

-- 按键处理函数
function processor.func(key_event, env)
    local context = env.engine.context
    
    -- 检查是否是配置的快捷键（这里使用 Control+y 作为默认快捷键）
    if key_event:repr() == "Control+y" then
        -- 获取当前选中的候选词
        local selected_candidate = context:get_selected_candidate()
        if selected_candidate then
            -- 记录高亮候选项到全局状态
            context:set_property("translation_highlighted", selected_candidate.text)
        end
        
        -- 设置全局触发标志
        context:set_property("translation_triggered", "1")
        
        -- 刷新输入上下文以触发过滤器
        context:refresh_non_confirmed_composition()
        return 1  -- kAccepted: 消费按键
    end
    
    return 2  -- kNoop: 不消费按键，继续处理
end

-- 过滤器模块
local filter = {}

-- 主过滤器函数
function filter.func(input, env)
    local context = env.engine.context
    local input_text = context.input

    -- 模式1：快捷键触发模式
    local triggered = context:get_property("translation_triggered") == "1"
    if triggered then
        context:set_property("translation_triggered", "")  -- 重置标志
        
        -- 获取高亮候选项
        local highlighted = context:get_property("translation_highlighted") or ""
        context:set_property("translation_highlighted", "")  -- 重置
        
        if highlighted == "" then
            yield(Candidate("error", 0, 0, "[无高亮候选项]", "请先高亮候选词"))
            for cand in input:iter() do yield(cand) end
            return
        end
        
        -- 执行翻译
        local translated_text = trans(highlighted)
        
        if not translated_text then
            yield(Candidate("error", 0, #input_text, "[翻译失败]", "请检查网络或API配置"))
            
            for cand in input:iter() do
                yield(cand)
            end
            return
        end
        
        -- 产生翻译候选词
        yield(Candidate("translation", 0, #input_text, translated_text, "[译] "..highlighted))
        
        -- 继续输出原始候选词
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- 模式2：后缀触发模式
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

-- 清理函数
function filter.fini(env)
    -- 清理全局状态
    local ctx = env.engine.context
    ctx:set_property("translation_triggered", "")
    ctx:set_property("translation_highlighted", "")
end

-- 返回模块
return { processor = processor, filter = filter }
