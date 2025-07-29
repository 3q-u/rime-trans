# Rime 候选词翻译插件

这是一个为 Rime 输入法设计的候选词翻译插件，可以在输入中文时快速获取英文翻译。通过简单的快捷键或特定触发方式，即可实时翻译当前输入的中文词语，提高双语输入效率。

![468703772-a35610b6-6e5b-453e-b763-ab2462686458.gif](https://s2.loli.net/2025/07/30/XfBvJG8AnitK9Fh.gif)

## 功能特点

- **多种触发方式**：
  - 快捷键触发（默认 Ctrl+Y）：选中候选词后按下快捷键获取翻译（默认第一个候选词）
  - 后缀触发：输入两个单引号(`''`)自动翻译第一个候选词（不可选择候选词）
- **多种翻译 API 支持**：
  - Google 翻译（默认，无需 API 密钥）
  - DeepL 翻译（需要 API 密钥）
  - Microsoft 翻译（需要 API 密钥）
  - 小牛云翻译（需要 API 密钥）
  - 有道翻译（需要 API 密钥）
  - 百度翻译（需要 API 密钥）
- **简洁的界面**：翻译结果显示在候选词列表首位，前缀标记为`[译]`
- **完整的日志记录**：方便调试和问题排查

## 安装方法

1. 确保您已经安装了 Rime 输入法
2. 从 [GitHub Releases](https://github.com/3q-u/rime-trans/releases) 下载最新版本
3. 根据您的操作系统，按照以下步骤安装：

### Windows (小狼毫 >= 0.14.0)
- 将 `out-mingw` 下所有文件复制到小狼毫的**程序**文件夹下
- 将 `lua` 下所有文件复制到小狼毫的**用户目录**下 (`%APPDATA%\Rime`)

### Linux
- 确保 librime 已编译 lua 支持
- 将 `out-linux` 下所有文件复制到 `/usr/local/lib/lua/$LUAV` 下
- 将 `lua` 下所有文件复制到**用户目录**下 (`~/.config/rime`)

### macOS (小企鹅)
- 将 `out-macos` 下所有文件复制到 `/usr/local/lib/lua/$LUAV` 下
- 将 `lua` 下所有文件复制到 `~/.local/share/fcitx5/rime` 下

4. 在您的输入方案配置文件（如 `<方案名>.schema.yaml`）中添加以下内容：

```yaml
engine:
  processors:
    - lua_processor@*input_text*processor # 候选词翻译
  filters:
    - lua_filter@*input_text*filter   # 候选词翻译
```

5. 重新部署 Rime 输入法

## 使用方法

### 快捷键触发模式
1. 在输入过程中，使用方向键或数字键选中需要翻译的候选词
2. 按下 `Ctrl+Y` 快捷键
3. 翻译结果将显示在候选词列表的首位，前缀标记为 `[译]`

### 后缀触发模式
1. 在输入过程中，输入两个单引号 `''`
2. 系统会自动翻译**第一个**候选词
3. 翻译结果将显示在候选词列表的首位，前缀标记为 `[译]`

## 配置说明

所有配置都在 `lua/trans-all.lua` 文件的开头部分：

```lua
-- 翻译API配置
local config = {
    -- 选择使用的翻译API: "google", "deepl", "microsoft", "niutrans", "youdao", "baidu" 
    default_api = "google",
    
    -- API密钥配置
    api_keys = {
        deepl = "YOUR_DEEPL_API_KEY", -- DeepL API密钥
        microsoft = {
            key = "YOUR_MS_TRANSLATOR_API_KEY", -- Microsoft Translator API密钥
            region = "global" -- 替换为您的区域
        },
        niutrans = "YOUR_NIUTRANS_API_KEY", -- 小牛云翻译API密钥
        youdao = {
            app_id = "YOUR_YOUDAO_APP_ID", -- 有道翻译应用ID
            app_key = "YOUR_YOUDAO_APP_KEY" -- 有道翻译应用密钥
        },
        baidu = {
            app_id = "YOUR_BAIDU_APP_ID", -- 百度翻译应用ID
            app_key = "YOUR_BAIDU_APP_KEY" -- 百度翻译应用密钥
        }
    }
}
```

### 设置默认翻译 API

修改 `default_api` 参数的值，可选项有：
- `google` - Google 翻译（默认，无需 API 密钥）
- `deepl` - DeepL 翻译（需要 API 密钥）
- `microsoft` - Microsoft 翻译（需要 API 密钥）
- `niutrans` - 小牛云翻译（需要 API 密钥）
- `youdao` - 有道翻译（需要 API 密钥）
- `baidu` - 百度翻译（需要 API 密钥）

### 配置 API 密钥

如果您选择使用需要 API 密钥的翻译服务，需要在配置中填写相应的 API 密钥。请参考各翻译服务提供商的官方文档获取 API 密钥。

## 调试功能

插件提供了完整的日志功能，可以帮助您排查问题：

```lua
-- 日志文件保存位置
-- Windows: %APPDATA%\rime\test-debug.log
-- Linux/macOS: HOME/.config/rime/test-debug.log
local log = require("log")

log.info("输出信息……")
log.error("输出错误信息……")
```

如果翻译功能不工作，请检查以下几点：

1. 确保您的网络连接正常
2. 如果使用需要 API 密钥的翻译服务，确保 API 密钥正确配置
3. 查看日志文件中是否有错误信息
4. 重新部署 Rime 输入法

## 注意事项

1. Google 翻译不需要 API 密钥，可以直接使用，但可能受到网络环境限制
2. 其他翻译 API 需要配置相应的 API 密钥
3. 翻译功能需要网络连接
4. 翻译结果的质量取决于所使用的翻译 API
5. 百度翻译 API 可能需要特定的网络环境才能正常工作

## 致谢

- [rime输入法实现候选词翻译](https://github.com/MrStrangerYang/simonLua) - 提供了最初的实现思路
- [librime-cloud](https://github.com/hchunhui/librime-cloud) - RIME 云输入插件（词云联想）
- [@Jormungand-x](https://github.com/Jormungand-x)
## 许可证

本项目遵循开源协议，欢迎贡献和改进。