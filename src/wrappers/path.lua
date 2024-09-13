---@meta _

---@class PathDriveAndRoot
---@field drive string|NIL
---@field root string|NIL

---@class PathExpandOptions
---@field base Path|string?
---@field home Path|string|boolean?
---@field expand_base boolean?

---@class (exact) Path
---@field new fun(path: string?): self
---@field home fun(): self
---@field is_absolute fun(self): boolean
---@field anchor fun(self): self?
---@field basename fun(self, suffix: string?): string
---@field dirname fun(self): string
---@field drive fun(self): self?
---@field drive_and_root fun(self): PathDriveAndRoot
---@field each_parent fun(self, cb: fun(path: Path))
---@field each_part fun(self, cb: fun(str: string))
---@field ends_with_separator fun(self): boolean
---@field expand fun(self, options: PathExpandOptions?)
---@field extension fun(self): string
---@field join fun(self, parts: string[]|string): self
---@field normalize fun(self, remove_final_separator: boolean?)
---@field parent fun(self): self
---@field parents fun(self): self[]
---@field parts fun(self): string[]
---@field relative_to fun(self, base: self|string): self
---@field is_relative_to fun(self, base: self|string): self?
---@field root fun(self): self?
---@field sibling fun(self, name: self|string): self
---@field stem fun(self): string
---@operator concat(): string
Path = {}
