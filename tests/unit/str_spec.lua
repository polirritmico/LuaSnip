local ls_helpers = require("helpers")
local exec_lua, feed, exec =
	ls_helpers.exec_lua, ls_helpers.feed, ls_helpers.exec

local works = function(msg, string, left, right, expected)
	it(msg, function()
		-- normally `exec_lua` accepts a table which is passed to the code as `...`, but it
		-- fails if number- and string-keys are mixed ({1,2} works fine, {1, b=2} fails).
		-- So we limit ourselves to just passing strings, which are then turned into tables
		-- while load()ing the function.
		local result = exec_lua(string.format(
			[[
					local res = {}
					for from, to in require("luasnip.util.str").unescaped_pairs("%s", "%s", "%s") do
						table.insert(res, {from, to})
					end
					return res
				]],
			string,
			left,
			right
		))
		assert.are.same(expected, result)
	end)
end

describe("str.unescaped_pairs", function()
	-- apparently clear() needs to run before anything else...
	ls_helpers.clear()
	ls_helpers.exec("set rtp+=" .. os.getenv("LUASNIP_SOURCE"))

	-- double \, since it is turned into a string twice.
	works(
		"simple parenthesis",
		"a (bb) c (dd\\\\)) e",
		"(",
		")",
		{ { 3, 6 }, { 10, 15 } }
	)
	works(
		"both parens escaped",
		"a \\\\(bb\\\\) c (dd\\\\)) e",
		"(",
		")",
		{ { 12, 17 } }
	)
	works("left=right", "``````", "`", "`", { { 1, 2 }, { 3, 4 }, { 5, 6 } })
	works(
		"random escaped characters",
		"`a`e`\\\\``i`",
		"`",
		"`",
		{ { 1, 3 }, { 5, 8 } }
	)
	works(
		"double escaped = literal `\\`",
		"`a`e`\\\\\\\\``i`",
		"`",
		"`",
		{ { 1, 3 }, { 5, 8 }, { 9, 11 } }
	)
end)

describe("str.multiline_substr", function()
	-- apparently clear() needs to run before anything else...
	ls_helpers.clear()
	ls_helpers.exec("set rtp+=" .. os.getenv("LUASNIP_SOURCE"))

	local function check(dscr, str, from, to, expected)
		it(dscr, function()
			assert.are.same(
				expected,
				exec_lua(
					[[
				local str, from, to = ...
				return require("luasnip.util.str").multiline_substr(str, from, to)
			]],
					str,
					from,
					to
				)
			)
		end)
	end

	check(
		"entire range",
		{ "asdf", "qwer" },
		{ 0, 0 },
		{ 1, 4 },
		{ "asdf", "qwer" }
	)
	check(
		"partial range",
		{ "asdf", "qwer" },
		{ 0, 3 },
		{ 1, 2 },
		{ "f", "qw" }
	)
	check(
		"another partial range",
		{ "asdf", "qwer" },
		{ 1, 2 },
		{ 1, 3 },
		{ "e" }
	)
	check(
		"one last partial range",
		{ "asdf", "qwer", "zxcv" },
		{ 0, 2 },
		{ 2, 4 },
		{ "df", "qwer", "zxcv" }
	)
	check("empty range", { "asdf", "qwer", "zxcv" }, { 0, 2 }, { 0, 2 }, { "" })
end)
