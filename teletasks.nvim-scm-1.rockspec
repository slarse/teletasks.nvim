rockspec_format = "3.0"
package = "teletasks.nvim"
version = "scm-1"

test_dependencies = {
	"lua >= 5.1",
	"telescope.nvim",
	"plenary.nvim",
}

dependencies = {
	"telescope.nvim",
}

source = {
	url = "git://github.com/slarse/" .. package,
}

build = {
	type = "builtin",
}
