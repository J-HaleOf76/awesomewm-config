--- Module: components
--
-- This Lua module acts as a factory for creating UI components within a dynamic system,
-- likely part of a window management or desktop environment. It leverages a modular design
-- where components can be dynamically loaded based on configuration settings and environmental
-- conditions. The module supports conditional logic for handling multiple monitors and
-- can be extended to include themes.
--
-- Dependencies:
--  - `require`: Used to dynamically load Lua modules specific to component configurations.
--  - `naughty`: Used for displaying notifications in case of errors.
--
-- @module components
-- @table components
local components = {}

local naughty = require("naughty")

--- Creates and initializes an instance of the specified component based on system
-- and display settings, attempting to load the most specific module first before falling back to less specific ones.
-- @function create_component
-- @param component_name The name of the component to be created.
-- @param s A table representing the screen on which the component will be initialized.
--    This table contains at least an `index` field to identify the screen number.
-- @param dsconfig Configuration data specific to the display settings. This includes:
--    - `is_multiple_monitors`: A boolean field to determine the configuration type.
--    - `theme_name`: Optional theme name to specify theme-specific component modules.
-- @return component The newly created component instance if creation is successful; nil otherwise.
-- @usage
-- local screen_settings = {index = 1}
-- local display_settings = {is_multiple_monitors = true, theme_name = "dark"}
-- local component = create_component('taglist', screen_settings, display_settings)
local function create_component(component_name, s, dsconfig)
    -- Determine the base path for component modules
    local base_path = 'fishlive.widget.factory.'
    local theme_name = dsconfig.theme_name .. '_'
    local sharedPrefix = dsconfig.is_multiple_monitors and 'shared_' or ''

    -- Attempt to dynamically load the most specific module first
    local module_names = {
        base_path .. sharedPrefix .. theme_name .. component_name,
        base_path .. theme_name .. component_name,
        base_path .. sharedPrefix .. component_name,
        base_path .. "standard_" .. component_name
    }

    local cmpModule = nil
    for _, mod_name in ipairs(module_names) do
        local status, mod = pcall(require, mod_name)
        if status then
            cmpModule = mod
            break
        end
    end

    if not cmpModule then
        naughty.notify{
            preset = naughty.config.presets.critical,
            title = 'Component UI Factory',
            text = "UI Component module not found for: " .. component_name}
        error("UI Component module not found for: " .. component_name)
    end

    -- initialize environment on the first screen only (call at once)
    if s.index == 1 and cmpModule.init_environment then
        cmpModule.init_environment(dsconfig)
    end

    -- create component instance
    local component = nil
    if cmpModule.create then
        component = cmpModule.create(s, dsconfig)
    end

    -- optional: add component's shortcuts
    if cmpModule.keys then
        cmpModule.keys(s, dsconfig)
    end

    return component
end

--------------------------------
-- Available components list
--------------------------------

--- Factory function to create and return an instance of the 'taglist' component.
-- @function taglist
-- @param s The screen information.
-- @param dsconfig The display settings configuration.
-- @return Returns the result from `create_component` function, specifically creating a 'taglist' component.
-- @usage
-- local screen = {index = 1}
-- local config = {is_multiple_monitors = false, theme_name = "default"}
-- local taglist = components.taglist(screen, config)
components.taglist = function(s, dsconfig)
    return create_component('taglist', s, dsconfig)
end

--- Factory function to create and return an instance of the 'naughty' component.
-- This is typically used for notification widgets.
-- @function naughty
-- @param s The screen information.
-- @param dsconfig The display settings configuration.
-- @return Returns the result from `create_component` function, specifically creating a 'naughty' component.
-- @usage
-- local screen = {index = 1}
-- local config = {is_multiple_monitors = true, theme_name = "modern"}
-- local naughty_component = components.naughty(screen, config)
components.naughty = function(s, dsconfig)
    return create_component('naughty', s, dsconfig)
end

-- Add next components...

return components