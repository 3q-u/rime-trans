-- local log = require("log")  日志方法
local http = require("simplehttp")
local json = require("json")

-- 翻译API配置
local config = {
    -- 选择使用的翻译API: "google", "deepl", "microsoft", "deeplx", "niutrans"
    default_api = "deeplx",
    
    -- API密钥配置
    api_keys = {
        deepl = "YOUR_DEEPL_API_KEY", -- 替换为您的DeepL API密钥
        microsoft = {
            key = "YOUR_MS_TRANSLATOR_API_KEY", -- 替换为您的Microsoft Translator API密钥
            region = "global" -- 替换为您的区域
        },
        niutrans = "" -- 替换为您的小牛云翻译API密钥
    },
    
    -- DeepLX服务器地址
    -- 请选择一个可用的服务器并取消注释，或者添加您自己的服务器
    deeplx_url = "",
    deeplx_token = nil,
}

-- URL编码函数
local function url_encode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w %-%_%.%~])",
            function(c)
                return string.format("%%%02X", string.byte(c))
            end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

-- Google翻译API
local function google(text)
    local encoded_text = url_encode(text)
    local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=zh-CN&tl=en&dt=t&dt=bd&dt=rm&dt=qca&dt=at&dt=ss&dt=md&dt=ld&dt=ex&dj=1&q=" .. encoded_text
    
    local reply = http.request(url)
    local success, j = pcall(json.decode, reply)
    
    if success and j then
        if j.dict and j.dict[1] and j.dict[1].terms and j.dict[1].terms[1] then
            return j.dict[1].terms[1]
        end
        if j.sentences and j.sentences[1] and j.sentences[1].trans then
            return j.sentences[1].trans
        end
    end
    
    if reply then
        local _, _, terms = string.find(reply, '"terms":%[%"([^"]+)"')
        if terms then
            return terms
        end
        
        local _, _, translated = string.find(reply, '"trans":"([^"]+)"')
        if translated then
            return translated
        end
        
        local _, _, translated2 = string.find(reply, '%[%[%["([^"]+)"')
        if translated2 then
            return translated2
        end
    end
    
    return nil
end

-- DeepL翻译API
local function deepl(text)
    local api_key = config.api_keys.deepl
    if not api_key then
        return nil
    end
    
    local url = "https://api-free.deepl.com/v2/translate"
    local body = "auth_key=" .. api_key .. "&text=" .. url_encode(text) .. "&target_lang=EN"
    
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }
    
    local reply = http.request{
        url = url,
        method = "POST",
        headers = headers,
        data = body
    }
    local success, j = pcall(json.decode, reply)
    
    if success and j and j.translations and j.translations[1] and j.translations[1].text then
        return j.translations[1].text
    end
    
    return nil
end

-- Microsoft翻译API
local function microsoft(text)
    local api_key = config.api_keys.microsoft.key
    local region = config.api_keys.microsoft.region
    
    if not api_key then
        return nil
    end
    
    local url = "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&to=en"
    local body = json.encode({
        {["Text"] = text}
    })
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["Ocp-Apim-Subscription-Key"] = api_key,
        ["Ocp-Apim-Subscription-Region"] = region
    }
    
    local reply = http.request{
        url = url,
        method = "POST",
        headers = headers,
        data = body
    }
    local success, j = pcall(json.decode, reply)
    
    if success and j and j[1] and j[1].translations and j[1].translations[1] and j[1].translations[1].text then
        return j[1].translations[1].text
    end
    
    return nil
end

-- DeepLX翻译API
local function deeplx(text)
    local url = config.deeplx_url
    
    if not url or url == "" then
        log.error("DeepLX URL未配置")
        return nil
    end
    
    if type(text) ~= "string" then
        text = tostring(text)
    end
    
    local body_table = {
        text = text,
        source_lang = "ZH", 
        target_lang = "EN"
    }
    
    local success_encode, body = pcall(json.encode, body_table)
    if not success_encode then
        log.error("JSON编码失败: " .. tostring(body))
        return nil
    end
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    if config.deeplx_token then
        headers["Authorization"] = "Bearer " .. config.deeplx_token
    end
    
    log.info("发送POST请求到: " .. url)
    log.info("请求体: " .. body)
    
    local success_request, reply = pcall(function()
        return http.request{
            url = url,
            method = "POST",
            headers = headers,
            data = body
        }
    end)
    
    if not success_request then
        log.error("HTTP请求失败: " .. tostring(reply))
        return nil
    end
    
    if not reply or reply == "" then
        log.error("收到空响应")
        return nil
    end
    
    log.info("收到响应: " .. reply)
    
    local success_decode, j = pcall(json.decode, reply)
    
    if not success_decode then
        log.error("JSON解析失败: " .. tostring(j))
        return nil
    end
    
    if j and j.data then
        log.info("找到data字段: " .. tostring(j.data))
        return j.data
    elseif j and j.alternatives and j.alternatives[1] then
        log.info("找到alternatives字段: " .. tostring(j.alternatives[1]))
        return j.alternatives[1]
    elseif j and j.translation then
        log.info("找到translation字段: " .. tostring(j.translation))
        return j.translation
    elseif j and j.translatedText then
        log.info("找到translatedText字段: " .. tostring(j.translatedText))
        return j.translatedText
    end
    
    log.error("未找到有效的翻译结果")
    return nil
end

-- 小牛云翻译API
local function niutrans(text)
    local api_key = config.api_keys.niutrans
    if not api_key then
        return nil
    end
    
    local url = "https://api.niutrans.com/NiuTransServer/translation"

    local body = json.encode({
        from = "zh",
        to = "en",
        apikey = api_key,
        src_text = text
    })
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    local reply = http.request{
        url = url,
        method = "POST",
        headers = headers,
        data = body
    }
    
    if not reply or reply == "" then
        return nil
    end
    
    local success, j = pcall(json.decode, reply)
    if not success then
        return nil
    end
    
    if j.tgt_text then
        if type(j.tgt_text) == "string" then
            local inner_success, inner_json = pcall(json.decode, j.tgt_text)
            if inner_success and type(inner_json) == "table" then
                return inner_json.content
            else
                return j.tgt_text
            end
        elseif type(j.tgt_text) == "table" then
            if j.tgt_text.content then
                return j.tgt_text.content
            else
                for k, v in pairs(j.tgt_text) do
                    if type(v) == "string" then
                        return v
                    end
                end
                return nil
            end
        else
            return nil
        end
    elseif j.translation then
        return j.translation
    elseif j.result and j.result.translatedText then
        return j.result.translatedText
    else
        return nil
    end
end

-- 导出模块
return {
    google = google,
    deepl = deepl,
    microsoft = microsoft,
    deeplx = deeplx,
    niutrans = niutrans,
    config = config
}