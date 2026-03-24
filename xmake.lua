add_rules("mode.debug", "mode.release")

-- local xmake package recipes
add_repositories("my-repo repo")

-- deps (system sqlite to avoid extra build)
add_requires(
    "ygopro-core 0.0.4",
    "lua 5.3.*",
    "pybind11 2.13.*", "fmt 10.2.*", "glog 0.6.0",
    "sqlite3 3.43.0+200", {system = true},
    "sqlitecpp 3.2.1",    {system = true},
    "concurrentqueue 1.0.4", "unordered_dense 4.4.*"
)

-- Other deps can pull an unconstrained `lua` (e.g. 5.5). That `-L` wins before 5.3 and
-- `-llua` then resolves to a lib without `lua_newuserdata` (API moved in newer Lua).
add_requireconfs("**.lua", {version = "5.3.*", override = true})

target("ygopro_ygoenv")
    add_rules("python.module")  -- was: python.library
    add_files("ygoenv/ygoenv/ygopro/*.cpp")
    add_packages("pybind11", "fmt", "glog", "concurrentqueue", "sqlitecpp", "unordered_dense", "ygopro-core", "lua")
    -- Static `libygopro-core.a` references Lua; the linker must see `liblua` *after*
    -- that archive (or use a group), otherwise `lua_*` stay undefined in the .so.
    add_linkgroups("ygopro-core", "lua", {group = true})
    add_ldflags("-Wl,--no-as-needed")
    add_syslinks("dl", "m")
    set_languages("c++17")
    if is_mode("release") then
        -- LTO can drop transitive refs from static archives; keep extension link plain.
        set_policy("build.optimization.lto", false)
        add_cxxflags("-march=native")
    end
    add_includedirs("ygoenv")
    after_build(function (target)
        local install_target = "$(projectdir)/ygoenv/ygoenv/ygopro"
        os.cp(target:targetfile(), install_target)
        print("Copy target to " .. install_target)
    end)
