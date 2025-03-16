# Rime 候选词翻译插件

这是一个为 Rime 输入法设计的候选词翻译插件，可以在输入中文时快速获取英文翻译。



## 功能特点

- 在输入中文时，通过特定触发方式获取候选词的英文翻译
- 支持多种翻译 API：Google、DeepL、Microsoft、DeepLX、小牛云翻译、大模型（❎暂不支持，计划中）
- 翻译结果显示在候选词列表的首位
- 简洁的界面，翻译结果前只显示`[译]`标记

## 安装方法

1. 确保您已经安装了 Rime 输入法
2. 获取[Github Releases](https://github.com/3q-u/rime-trans/releases)
3. 将 `lua` 目录复制到您的 Rime **用户配置**目录中（默认位置）：
   - Windows: `%APPDATA%\Rime`
   - macOS: `~/Library/Rime`
   - Linux: `~/.config/rime`
4. - Windows 平台（小狼毫 >= 0.14.0）
     - 将 `out-mingw` 下所有文件复制到小狼毫的**程序**文件夹下
     - 将 `lua` 下所有文件复制到小狼毫的**用户目录**下
   - Linux 平台（librime 需编译 lua 支持）
     - 将 `out-linux` 下所有文件复制到 `/usr/local/lib/lua/$LUAV` 下
     - 将 `lua` 下所有文件复制到**用户目录**下
   - macOS 平台（小企鹅）
     - 将 `out-macos` 下所有文件复制到 `/usr/local/lib/lua/$LUAV` 下
     - 将 `lua` 下所有文件复制到 `~/.local/share/fcitx5/rime` 下
5. 在您的输入方案配置文件（如 `<方案名>.schema.yaml`）中添加以下内容：

```yaml
engine:
  filters:
    - lua_filter@*input_text   # 候选词翻译
```

4. 重新部署 Rime 输入法

## 使用方法

1. 在 Rime 输入法中输入中文
2. 在输入的末尾添加 `''`（两个单引号）
3. 系统会自动翻译第一个候选词，并将翻译结果放在候选词列表的最前面
4. 翻译结果前会显示"[译]"标记

例如，输入 `你好''` 后，候选词列表将显示：
1. `Hello [译]`
2. `你好`
3. （其他候选词...）

## 配置说明

所有配置都在 `lua/trans-all.lua` 文件的开头部分：

```lua
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
        niutrans = "YOUR_NIUTRANS_API_KEY" -- 替换为您的小牛云翻译API密钥
    },
    
    -- DeepLX服务器地址
    deeplx_url = "YOUR_DEEPLX_URL",
    deeplx_token = nil,
}
```

> 默认翻译第一个候选词，可自行修改

### 设置默认翻译 API

修改 `default_api` 参数的值，可选项有：
- `google` - Google 翻译（默认，无需 API 密钥）
- `deepl` - DeepL 翻译（需要 API 密钥）
- `microsoft` - Microsoft 翻译（需要 API 密钥）
- `deeplx` - DeepLX 翻译（需要服务器地址）
- `niutrans` - 小牛云翻译（需要 API 密钥）

### 配置 API 密钥

如果您选择使用需要 API 密钥的翻译服务，需要在配置中填写相应的 API 密钥。

### DeepLX 配置

DeepLX 是一个开源的 DeepL API 代理，可以免费使用。如果您选择使用 DeepLX，需要配置服务器地址：

```lua
deeplx_url = "https://xxx.xxx.xxx/translate",
```

如果服务器需要认证，还需要设置令牌：

```lua
deeplx_token = "your_token",
```

## 调试

在`lua/log.lua` 下给出了日志调试功能。

用法：

```lua
-- 日志文件保存位置
-- windows %APPDATA%\rime
-- linux  HOME/.config/rime
local log = require("log")  -- 引入log日志

log.info("输出信息……")
log.error("输出错误信息……")
```

如果翻译功能不工作，请检查以下几点：

1. 确保您的网络连接正常
2. 如果使用 DeepLX，确保服务器地址正确且可访问
3. 如果使用需要 API 密钥的翻译服务，确保 API 密钥正确
4. 重新部署 Rime 输入法

## 注意事项

1. Google 翻译不需要 API 密钥，可以直接使用
2. 其他翻译 API 需要配置相应的 API 密钥或服务器地址
3. 翻译功能需要网络连接
4. 翻译结果的质量取决于所使用的翻译 API

## 致谢

- [rime输入法实现候选词翻译](https://github.com/MrStrangerYang/simonLua)

- [librime-cloud: RIME 云输入插件](https://github.com/hchunhui/librime-cloud)（词云联想）