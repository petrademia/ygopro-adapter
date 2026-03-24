package("ygopro-core")

    set_homepage("https://github.com/mycard/ygopro-core")

    add_urls("https://github.com/mycard/ygopro-core.git")
    add_versions("0.0.4", "753ece19f0e28bea1b206c0f919799803c25ac9a")

    add_deps("lua 5.3.*")

    on_install("linux", function (package)
        io.writefile("xmake.lua", [[
            add_rules("mode.debug", "mode.release")
            -- Avoid requiring a system `lua` binary (not present in many setups).
            -- Also keep compatibility with ygopro-core's lua_resume() usage.
            add_requires("lua 5.3.*")
            target("ygopro-core")
                set_kind("static")
                add_files("*.cpp")
                add_headerfiles("*.h")
                add_packages("lua")
        ]])

        local check_and_insert = function(file, line, insert)
            local lines = table.to_array(io.lines(file))
            if lines[line] ~= insert then
                table.insert(lines, line, insert)
                io.writefile(file, table.concat(lines, "\n"))
            end
        end

        check_and_insert("field.h", 14, "#include <cstring>")
        check_and_insert("interpreter.h", 11, "extern \"C\" {")
        check_and_insert("interpreter.h", 15, "}")
        local configs = {}
        if package:config("shared") then
            configs.kind = "shared"
        end
        import("package.tools.xmake").install(package)
        os.cp("*.h", package:installdir("include", "ygopro-core"))
    end)
package_end()
