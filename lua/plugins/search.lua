-- Project-wide find and replace (VS Code: Cmd+Shift+H). fzf-lua finds matches;
-- this is the view that writes the changes back to disk.
return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  -- The view opens through lua/ui/search.lua, which places it as a full-height
  -- column beside the file tree. Its own keys are listed in the buffer header;
  -- inside it, the leader is the local leader, so `␣r` replaces everywhere.
  opts = {
    resultsHighlight = true,
    startInsertMode = true,
  },
}
