local api = vim.api

local actions = require('telescope/actions')
local finders = require('telescope/finders')
local pickers = require('telescope/pickers')
local previewers = require('telescope/previewers')

local licenses = require('licenses')
local util = require('licenses/util')

local m = {}

m.insert = function(opts)
    local origin_bufnr = api.nvim_get_current_buf()
    local config = licenses.get_config(origin_bufnr)
    pickers.new(
        opts,
        {
            prompt_title = 'licenses.nvim',
            finder = finders.new_table(
                { results = util.get_available_licenses() }
            ),
            sorter = require('telescope/config').values.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(
                    function()
                        actions.close(prompt_bufnr)
                        licenses.insert(origin_bufnr, 0, config)
                    end
                )
                return true
            end,
            previewer = previewers.new_buffer_previewer({
                define_preview = function(self, entry)
                    local bufnr = self.state.bufnr
                    api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
                    config.license = entry[1]
                    licenses.insert(bufnr, 0, config)
                end,
                dyn_title = function(_, entry) return entry[1] end,
            }),

        }
    ):find()
end

m.pick = function(opts)
    local origin_bufnr = api.nvim_get_current_buf()
    local selection
    pickers.new(
        opts,
        {
            prompt_title = 'licenses.nvim',
            finder = finders.new_table(
                { results = util.get_available_licenses() }
            ),
            sorter = require('telescope/config').values.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(
                    function()
                        actions.close(prompt_bufnr)
                        api.nvim_buf_set_var(
                            origin_bufnr, 'licenses_nvim_license', selection
                        )
                    end
                )
                return true
            end,
            previewer = previewers.new_buffer_previewer({
                define_preview = function(self, entry)
                    local bufnr = self.state.bufnr
                    api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
                    selection = entry[1]
                    if not selection then return end

                    vim.cmd.setlocal('wrap')
                    vim.fn.appendbufline(
                        bufnr,
                        0,
                        ---@diagnostic disable-next-line: param-type-mismatch
                        licenses.get_text(
                            util.get_file('text/' .. selection .. '.txt')
                        )
                    )
                end,
                dyn_title = function(_, entry) return entry[1] end,
            }),

        }
    ):find()
end

return require('telescope').register_extension({
    setup = function(config)
        print(vim.inspect(config))
        config = config or {}
        vim.validate({
            ext_config = { config, 'table' },
            default_action = { config.default_action, 'string', true },
        })
        m.default = m[config.default_action] or m.insert
    end,
    exports = {
        ['licenses-nvim'] = function(...) m.default(...) end,
        insert = m.insert,
        pick = m.pick,
    },
})