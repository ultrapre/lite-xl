local core = require "core"
local command = {}

---A predicate function accepts arguments from `command.perform()` and evaluates to a boolean. </br>
---If the function returns true, then the function associated with the command is executed.
---
---The predicate function can also return other values after the boolean, which will
---be passed into the function associated with the command.
---@alias core.command.predicate_function fun(...: any): boolean, ...

---A predicate is a string, an Object or a function, that is used to determine
---whether a command should be executed.
---
---If the predicate is a string, it is resolved into an `Object` via `require()`
---and checked against the active view with `Object:extends()`. </br>
---For example, `"core.docview"` will match any view that inherits from `DocView`. </br>
---A `!` can be appended to the predicate to strictly match the current view via `Object:is()`,
---instead of matching any view that inherits the predicate.
---
---If the predicate is a table, it is checked against the active view with `Object:extends()`.
---Strict matching via `Object:is()` is not available.
---
---If the predicate is a function, it must behave like a predicate function.
---@see core.command.predicate_function
---@alias core.command.predicate string|core.object|core.command.predicate_function

---A command is identified by a command name.
---The command name contains a category and the name itself, separated by a colon (':').
---
---All commands should be in lowercase and should not contain whitespaces; instead
---they should be replaced by a dash ('-').
---@alias core.command.command_name string

---The predicate and its associated function.
---@class core.command.command
---@field predicate core.command.predicate_function
---@field perform fun(...: any)

---@type { [string]: core.command.command }
command.map = {}

---@type core.command.predicate_function
local always_true = function() return true end


---This function takes in a predicate and produces a predicate function
---that is internally used to dispatch and execute commands.
---
---This function should not be called manually.
---@see core.command.predicate
---@param predicate core.command.predicate|nil If nil, the predicate always evaluates to true.
---@return core.command.predicate_function
function command.generate_predicate(predicate)
  predicate = predicate or always_true
  local strict = false
  if type(predicate) == "string" then
    if predicate:match("!$") then
      strict = true
      predicate = predicate:gsub("!$", "")
    end
    predicate = require(predicate)
  end
  if type(predicate) == "table" then
    local class = predicate
    if not strict then
      predicate = function(...) return core.active_view:extends(class), core.active_view, ... end
    else
      predicate = function(...) return core.active_view:is(class), core.active_view, ... end
    end
  end
  ---@cast predicate core.command.predicate_function
  return predicate
end


---Adds commands to the map.
---
---The function accepts a table containing a list of commands
---and their functions. </br>
---If a command already exists, it will be replaced.
---@see core.command.predicate
---@see core.command.command_name
---@param predicate core.command.predicate
---@param map { [core.command.command_name]: fun(...: any) }
function command.add(predicate, map)
  predicate = command.generate_predicate(predicate)
  for name, fn in pairs(map) do
    if command.map[name] then
      core.log_quiet("Replacing existing command \"%s\"", name)
    end
    command.map[name] = { predicate = predicate, perform = fn }
  end
end


-- 中文命令名（用于命令面板与状态栏显示）
local zh_names = {
  ["autocomplete:cancel"] = "取消自动补全",
  ["autocomplete:complete"] = "自动补全",
  ["autocomplete:cycle"] = "切换补全项",
  ["autocomplete:next"] = "下一个补全项",
  ["autocomplete:previous"] = "上一个补全项",
  ["command:complete"] = "补全输入",
  ["command:escape"] = "退出输入",
  ["command:select-next"] = "选择下一个",
  ["command:select-previous"] = "选择上一个",
  ["command:submit"] = "确认输入",
  ["context:focus-next"] = "聚焦下一个菜单项",
  ["context:focus-previous"] = "聚焦上一个菜单项",
  ["context:hide"] = "隐藏菜单",
  ["context:on-selected"] = "执行选中菜单项",
  ["context:show"] = "显示菜单",
  ["core:add-directory"] = "添加目录",
  ["core:change-project-folder"] = "切换项目文件夹",
  ["core:find-command"] = "执行命令",
  ["core:find-file"] = "打开项目文件",
  ["core:force-quit"] = "强制退出",
  ["core:new-doc"] = "新建文件",
  ["core:new-named-doc"] = "新建命名文件",
  ["core:open-file"] = "打开文件",
  ["core:open-log"] = "打开日志",
  ["core:open-project-folder"] = "打开项目文件夹",
  ["core:open-project-module"] = "打开项目配置文件",
  ["core:open-user-module"] = "打开用户配置文件",
  ["core:quit"] = "退出",
  ["core:reload-module"] = "重新加载模块",
  ["core:remove-directory"] = "移除目录",
  ["core:restart"] = "重启",
  ["core:toggle-fullscreen"] = "切换全屏",
  ["dialog:next-entry"] = "下一个选项",
  ["dialog:previous-entry"] = "上一个选项",
  ["dialog:select"] = "选择",
  ["dialog:select-no"] = "选择“否”",
  ["dialog:select-yes"] = "选择“是”",
  ["doc:backspace"] = "退格",
  ["doc:copy"] = "复制",
  ["doc:create-cursor-next-line"] = "在下一行添加光标",
  ["doc:create-cursor-previous-line"] = "在上一行添加光标",
  ["doc:cut"] = "剪切",
  ["doc:delete"] = "向后删除",
  ["doc:delete-lines"] = "删除行",
  ["doc:duplicate-lines"] = "复制当前行",
  ["doc:go-to-line"] = "跳转到行",
  ["doc:indent"] = "增加缩进",
  ["doc:join-lines"] = "合并行",
  ["doc:lower-case"] = "转为小写",
  ["doc:move-lines-down"] = "下移行",
  ["doc:move-lines-up"] = "上移行",
  ["doc:move-to-next-char"] = "向右移动一个字符",
  ["doc:move-to-previous-char"] = "向左移动一个字符",
  ["doc:newline"] = "换行",
  ["doc:newline-above"] = "在上方插入空行",
  ["doc:newline-below"] = "在下方插入空行",
  ["doc:paste"] = "粘贴",
  ["doc:redo"] = "重做",
  ["doc:reload"] = "重新载入",
  ["doc:save"] = "保存",
  ["doc:save-as"] = "另存为",
  ["doc:select-all"] = "全选",
  ["doc:select-lines"] = "选择行",
  ["doc:select-none"] = "取消选择",
  ["doc:select-to-cursor"] = "选择到光标处",
  ["doc:select-word"] = "选择单词",
  ["doc:set-cursor"] = "设置光标位置",
  ["doc:set-cursor-line"] = "将光标移到行首",
  ["doc:set-cursor-word"] = "将光标移到词首",
  ["doc:split-cursor"] = "拆分光标",
  ["doc:toggle-block-comments"] = "切换块注释",
  ["doc:toggle-line-comments"] = "切换行注释",
  ["doc:toggle-line-ending"] = "切换换行符",
  ["doc:undo"] = "撤销",
  ["doc:unindent"] = "减少缩进",
  ["doc:upper-case"] = "转为大写",
  ["file:delete"] = "删除文件",
  ["file:rename"] = "重命名文件",
  ["files:create-directory"] = "新建目录",
  ["find-replace:find"] = "查找",
  ["find-replace:previous-find"] = "查找上一个",
  ["find-replace:repeat-find"] = "查找下一个",
  ["find-replace:replace"] = "替换",
  ["find-replace:replace-symbol"] = "替换符号",
  ["find-replace:select-add-all"] = "添加全部匹配到选择",
  ["find-replace:select-add-next"] = "添加下一个匹配到选择",
  ["find-replace:select-next"] = "选中下一个匹配",
  ["find-replace:select-previous"] = "选中上一个匹配",
  ["find-replace:toggle-regex"] = "切换正则查找",
  ["find-replace:toggle-sensitivity"] = "切换区分大小写",
  ["indent:set-file-indent-size"] = "设置缩进宽度",
  ["indent:set-file-indent-type"] = "设置缩进类型",
  ["indent:switch-file-to-spaces-indentation"] = "使用空格缩进",
  ["indent:switch-file-to-tabs-indentation"] = "使用制表符缩进",
  ["lineguide:toggle"] = "切换参考线",
  ["log:copy-to-clipboard"] = "复制日志到剪贴板",
  ["log:open-as-doc"] = "在编辑器中打开日志",
  ["macro:play"] = "播放宏",
  ["macro:toggle-record"] = "录制/停止宏",
  ["project-search:find"] = "在项目中查找文本",
  ["project-search:find-regex"] = "在项目中正则查找",
  ["project-search:fuzzy-find"] = "在项目中模糊查找",
  ["project-search:select-next"] = "下一个搜索结果",
  ["project-search:select-previous"] = "上一个搜索结果",
  ["quote:quote"] = "添加引用",
  ["reflow:reflow"] = "重新排版",
  ["root:close"] = "关闭标签页",
  ["root:close-all"] = "关闭全部标签页",
  ["root:close-all-others"] = "关闭其他标签页",
  ["root:close-or-quit"] = "关闭标签页或退出",
  ["root:grow"] = "扩大视图",
  ["root:horizontal-scroll"] = "水平滚动",
  ["root:move-tab-left"] = "标签页左移",
  ["root:move-tab-right"] = "标签页右移",
  ["root:scroll"] = "滚动",
  ["root:shrink"] = "缩小视图",
  ["root:switch-to-next-tab"] = "切换到下一个标签页",
  ["root:switch-to-previous-tab"] = "切换到上一个标签页",
  ["scale:decrease"] = "缩小界面",
  ["scale:reset"] = "重置界面缩放",
  ["scale:increase"] = "放大界面",
  ["status-bar:disable-messages"] = "禁用状态栏消息",
  ["status-bar:enable-messages"] = "启用状态栏消息",
  ["status-bar:hide"] = "隐藏状态栏",
  ["status-bar:hide-item"] = "隐藏状态栏项",
  ["status-bar:reset-items"] = "重置状态栏项",
  ["status-bar:show"] = "显示状态栏",
  ["status-bar:show-item"] = "显示状态栏项",
  ["status-bar:toggle"] = "切换状态栏",
  ["tabularize:tabularize"] = "表格对齐",
  ["toolbar:toggle"] = "切换工具栏",
  ["treeview:collapse"] = "折叠目录",
  ["treeview:delete"] = "删除",
  ["treeview:deselect"] = "取消选择",
  ["treeview:expand"] = "展开目录",
  ["treeview:new-file"] = "新建文件",
  ["treeview:new-folder"] = "新建文件夹",
  ["treeview:next"] = "下一个条目",
  ["treeview:open"] = "打开",
  ["treeview:open-in-system"] = "在系统中打开",
  ["treeview:previous"] = "上一个条目",
  ["treeview:remove-project-directory"] = "移除项目目录",
  ["treeview:rename"] = "重命名",
  ["treeview:search-in-directory"] = "在目录中搜索",
  ["treeview:select"] = "选择条目",
  ["treeview:select-and-open"] = "选择并打开",
  ["treeview:toggle"] = "切换文件树",
  ["treeview:toggle-focus"] = "聚焦文件树",
  ["draw-whitespace:disable"] = "隐藏空白字符",
  ["draw-whitespace:enable"] = "显示空白字符",
  ["draw-whitespace:toggle"] = "切换显示空白字符",
  ["line-wrapping:disable"] = "关闭自动换行",
  ["line-wrapping:enable"] = "开启自动换行",
  ["line-wrapping:toggle"] = "切换自动换行",
  ["project-search:move-to-end-of-doc"] = "移动到结果末尾",
  ["project-search:move-to-next-page"] = "下一个结果页",
  ["project-search:move-to-previous-page"] = "上一个结果页",
  ["project-search:move-to-start-of-doc"] = "移动到结果开头",
  ["project-search:open-selected"] = "打开选中的结果",
  ["project-search:refresh"] = "刷新搜索结果",
  ["trim-whitespace:trim-empty-end-lines"] = "删除末尾空行",
  ["trim-whitespace:trim-trailing-whitespace"] = "删除行尾空白",
  -- 状态栏项名称
  ["doc:file"] = "文件",
  ["doc:position"] = "光标位置",
  ["doc:indentation"] = "缩进",
  ["doc:lines"] = "行数",
  ["doc:line-ending"] = "换行符",
}

local function capitalize_first(str)
  return str:sub(1, 1):upper() .. str:sub(2)
end

---Prettifies the command name.
---
---This function adds a space between the colon and the command name,
---replaces dashes with spaces and capitalizes the command appropriately.
---@see core.command.command_name
---@param name core.command.command_name
---@return string
function command.prettify_name(name)
  if zh_names[name] then
    return zh_names[name]
  end
  ---@diagnostic disable-next-line: redundant-return-value
  return name:gsub(":", ": "):gsub("-", " "):gsub("%S+", capitalize_first)
end


---Returns all the commands that can be executed (their predicates evaluate to true).
---@return core.command.command_name[]
function command.get_all_valid()
  local res = {}
  local memoized_predicates = {}
  for name, cmd in pairs(command.map) do
    if memoized_predicates[cmd.predicate] == nil then
      memoized_predicates[cmd.predicate] = cmd.predicate()
    end
    if memoized_predicates[cmd.predicate] then
      table.insert(res, name)
    end
  end
  return res
end

---Checks whether a command can be executed (its predicate evaluates to true).
---@param name core.command.command_name
---@param ... any
---@return boolean
function command.is_valid(name, ...)
  return command.map[name] and command.map[name].predicate(...)
end

local function perform(name, ...)
  local cmd = command.map[name]
  if not cmd then return false end
  local res = { cmd.predicate(...) }
  if table.remove(res, 1) then
    if #res > 0 then
      -- send values returned from predicate
      cmd.perform(table.unpack(res))
    else
      -- send original parameters
      cmd.perform(...)
    end
    return true
  end
  return false
end


---Performs a command.
---
---The arguments passed into this function are forwarded to the predicate function. </br>
---If the predicate function returns more than 1 value, the other values are passed
---to the command.
---
---Otherwise, the arguments passed into this function are passed directly
---to the command.
---@see core.command.predicate
---@see core.command.predicate_function
---@param name core.command.command_name
---@param ... any
---@return boolean # true if the command is performed successfully.
function command.perform(name, ...)
  local ok, res = core.try(perform, name, ...)
  return not ok or res
end


---Inserts the default commands for Lite XL into the map.
function command.add_defaults()
  local reg = {
    "core", "root", "command", "doc", "findreplace",
    "files", "dialog", "log", "statusbar"
  }
  for _, name in ipairs(reg) do
    require("core.commands." .. name)
  end
end


return command
