local core = require "core"
local command = require "core.command"
local common = require "core.common"

command.add(nil, {
  ["files:create-directory"] = function()
    core.command_view:enter("新目录名称", {
      submit = function(text)
        local success, err, path = common.mkdirp(text)
        if not success then
          core.error("无法创建目录 %q：%s", path, err)
        end
      end
    })
  end,
})
