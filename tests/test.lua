local teletasks = require("teletasks")

describe("TickBox", function()
	it("Should tick unticked box", function()
		local selection = { filename='tests/blabla.md', lnum=1, col=1 }
		teletasks.TickBox(selection)
	end)
end)
