local utilities = {}

-- Recursively print the contents of a table.
local function print_rec(thing, skip_newline, level)
   level = level or 4
   if (type(thing) == "table") then
      if level <= 0 then
         io.write('...')
      else
         io.write('{')
         local sep = ''
         for _,v in ipairs(thing) do
            io.write(sep);
            print_rec(v, true, level - 1);
            sep = ', '
         end
         for k,v in pairs(thing) do
            if (type(k) ~= 'number') then
               io.write(sep, k, ' = ');
               print_rec(v, true, level - 1);
               sep = ', '
            end
         end
         io.write('}')
      end
   else
      io.write(tostring(thing))
   end
   if (not skip_newline) then
      print()
   end
end
utilities.print_rec = print_rec

-- Generate a string containing the contents of a table.
local function table_tostring (thing, level)
   level = (type(level) == "number" and level) or 4
   if level <= 0 then
      return "..."
   end

   local result = {}
   local function push (item)
      result[#result + 1] = item
   end 
   if (type(thing) == "table") then
      push('{')
      local sep = ''
      for _,v in ipairs(thing) do
         push(sep); push(table_tostring(v, level - 1));
         sep = ', '
      end
      for k,v in pairs(thing) do
         if (type(k) ~= 'number') then
            push(sep); push(k); push(' = ');
            push(table_tostring(v, level - 1));
            sep = ', '
         end
      end
      push('}')
      return table.concat(result)
   elseif type(thing) == "string" then
      return '"' .. thing .. '"'
   else
      return tostring(thing)
   end
end
utilities.table_tostring = table_tostring

-- Print a table in tabular form; print nested tables with
-- print_rec
local function print_table(tab)
   if (type(tab) == 'table') then
      for k,v in pairs(tab) do
         io.write(k, '\t -> ')
         print_rec(v, true)
         -- io.write('\ttype: ', type(v))
         print()
      end
   else
      print(tab)
   end
end
utilities.print_table = print_table

local function running_average (old_avg, n_old, new_val)
  local n_new = n_old + 1
  return old_avg + (new_val - old_avg)/n_new, n_new
end
utilities.running_average = running_average

return utilities
