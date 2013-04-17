require('numlua')
local util = require('utilities')

local function bandit_action (bandit, action)
  assert(action <= #bandit, "bad action")
  local res = rng.rnorm(bandit[action], 1)
  local avg, n = bandit.avg, bandit.num_actions
  bandit.avg, bandit.num_actions = util.running_average(avg, n, res)
  return res
end

local function print_bandit_info (bandit)
  local format = string.format
  io.write(format("%16s: max = %6.3f, dist = ", "Bandit", bandit.max))
  for i,v in ipairs(bandit) do
    if i == 1 then io.write("{") else io.write(", ") end
    io.write(format("%5.2f", v))
  end
  io.write("}\n")
end
  
local bandit_metatable = {
  __index = {
    action = bandit_action,
    print_info = print_bandit_info,
  }
}

-- Create an n-armed bandit
local function make_bandit (n)
  n =  n or 10
  local bandit = {}
  local max = -math.huge
  local max_index = 0
  for i = 1,10 do
    local val = rng.rnorm(0, 1)
    bandit[i] = val
    if val > max then
      max = val
      max_index = i
    end
    bandit.max = max
    bandit.max_index = max_index
    bandit.avg = 0
    bandit.num_actions = 0
  end
  setmetatable(bandit, bandit_metatable)
  return bandit
end

local function choose_random_action (strategy)
  local bandit = strategy.bandit
  local actions = #bandit
  local res = math.random(actions)
  strategy.last_action = res
  return res
end

local function random_action_reward (strategy, reward)
  strategy.total_reward = strategy.total_reward + reward
  strategy.num_choices = strategy.num_choices + 1
end

local function strategy_step (strategy)
  local bandit = strategy.bandit
  strategy:reward(bandit:action(strategy:choose_action()))
end
 
local function print_strategy_info (strategy)
  local format = string.format
  local total_reward, num_choices = strategy.total_reward, strategy.num_choices
  local max_reward = strategy.bandit.max 
  local avg_reward = num_choices > 0 and total_reward/num_choices or num_choices
  io.write(format("%16s: avg = %6.3f ~ %5.1f%%, total = %11.3f, #choices = %3d\n",
      strategy.type .. (strategy.display_parameter or ""),
      avg_reward,
      100 * avg_reward/max_reward,
      total_reward,
      num_choices))
end

local random_strategy_metatable = {
  __index = {
    type = "Random",
    choose_action = choose_random_action,
    reward = random_action_reward,
    step = strategy_step,
    print_info = print_strategy_info,
  },
}

local function make_random_strategy (bandit)
  local res = {
    bandit = bandit,
    total_reward = 0,
    num_choices = 0,
    last_action = 1,
  }
  setmetatable(res, random_strategy_metatable)
  return res
end

local function choose_greedy_action (strategy)
  local bandit = strategy.bandit
  local action, value = 0, -math.huge
  for i = 1,#bandit do
    local cur_value = strategy[i].avg_reward
    if cur_value > value then
      action, value = i, cur_value
    end
  end
  strategy.last_action = action
  return action
end

local function greedy_action_reward (strategy, reward)
  local running_average = util.running_average
  local info = strategy[strategy.last_action]
  local avg_reward = info.avg_reward
  local num_chosen = info.num_chosen
  info.avg_reward, info.num_chosen = running_average(avg_reward, num_chosen, reward)
  strategy.total_reward = strategy.total_reward + reward
  strategy.num_choices = strategy.num_choices + 1
end
 
local greedy_strategy_metatable = {
  __index = {
    type = "Greedy",
    choose_action = choose_greedy_action,
    reward = greedy_action_reward,
    step = strategy_step,
    print_info = print_strategy_info,
  },
}

local function make_strategy_table (bandit)
  local res = {
    bandit = bandit,
    total_reward = 0,
    num_choices = 0,
    last_action = 1,
  }
  for i = 1,#bandit do
    res[i] = { avg_reward = 0, num_chosen = 0 }
  end
  return res
end

local function make_greedy_strategy (bandit)
  local res = make_strategy_table(bandit)
  setmetatable(res, greedy_strategy_metatable)
  return res
end

local function choose_epsilon_greedy_action (strategy)
  local epsilon = strategy.epsilon
  if (math.random() < epsilon) then
    return choose_random_action(strategy)
  else 
    return choose_greedy_action(strategy)
  end
end

local epsilon_strategy_metatable = {
  __index = {
    type = "Epsilon",
    choose_action = choose_epsilon_greedy_action,
    reward = greedy_action_reward,
    step = strategy_step,
    print_info = print_strategy_info,
  },
}
    
local function make_epsilon_strategy (bandit, epsilon)
  local res = make_strategy_table(bandit)
  res.epsilon = epsilon or 0.01
  res.display_parameter = string.format(" (%5.3f)", epsilon)
  setmetatable(res, epsilon_strategy_metatable)
  return res
end

local function choose_varepsilon_greedy_action (strategy)
  local epsilon = strategy.epsilon
  strategy.epsilon = 0.99 * strategy.epsilon
  if (math.random() < epsilon) then
    return choose_random_action(strategy)
  else 
    return choose_greedy_action(strategy)
  end
end


local varepsilon_strategy_metatable = {
  __index = {
    type = "VarEps",
    choose_action = choose_varepsilon_greedy_action,
    reward = greedy_action_reward,
    step = strategy_step,
    print_info = print_strategy_info,
  },
}
    
local function make_varepsilon_strategy (bandit, epsilon)
  local res = make_strategy_table(bandit)
  res.epsilon = epsilon or 1
  -- res.display_parameter = string.format(" (%5.3f)", epsilon)
  setmetatable(res, varepsilon_strategy_metatable)
  return res
end


for i = 1,10 do
  local avg = 0
  local b = make_bandit()
  local rs = make_random_strategy(b)
  local gs = make_greedy_strategy(b)
  local e001s = make_epsilon_strategy(b, 0.01)
  local e010s = make_epsilon_strategy(b, 0.10)
  local ves = make_varepsilon_strategy(b)
  for j = 1,100000 do
    rs:step()
    gs:step()
    e001s:step()
    e010s:step()
    ves:step()
  end
  b:print_info()
  rs:print_info()
  gs:print_info()
  e001s:print_info()
  e010s:print_info()
  ves:print_info()
  print()
end
