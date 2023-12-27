local addonName, addonData = ...
SLASH_ECONOMY1 = "/economy";
SLASH_RESETECONOMY1 = "/economyreset";

local TSM_API = nil;
local DEFAULT_RUNE_PRICE = 6000000;

local function log(name, value)
  print(name.." = "..tostring(value))
end
local myFrame = CreateFrame("Frame");

myFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
myFrame:RegisterEvent("ADDON_LOADED");
myFrame:RegisterEvent("PLAYER_DEAD");
myFrame:SetScript("OnEvent",
  function(self, event, arg1, arg2, arg3, arg4)
    if (event == "ADDON_LOADED" and arg1 == "DraconicEconomy") then
      if AugmentUses == nil then
        AugmentUses = 0;
      end
      if CumulativeSavings == nil then
        CumulativeSavings = 0;
      end
      if LastAugmentUse == nil then
        LastAugmentUse = 0;
      end
    end
    if (event == "UNIT_SPELLCAST_SUCCEEDED" and arg3 == 393438 and arg1 == "player") then
      CurrentTime = time();
      NextEligibleTime = LastAugmentUse + (60 * 60)
      if CurrentTime > NextEligibleTime then
        SetCurrentPrice();
        IncrementCosts();
        PrintOutput();
      else
        print("Augment Use detected, but too recent to count");
        print("Current Time: "..date("%Y-%m-%d %H:%M:%S", CurrentTime));
        print("Next Eligible Time: "..date("%Y-%m-%d %H:%M:%S", NextEligibleTime));
      end
  end
    if (event == "PLAYER_DEAD") then
      print("Resetting augment rune eligibility.");
      LastAugmentUse = 0;
    end
  end
);

function GetTSM()
  if not TSM_API then
    if getglobal("TSM_API") then
      print("Draconic Economy - TSM Enabled");
      TSM_API = getglobal("TSM_API");
    else
      MockTSM = {};
      MockTSM.__index = MockTSM;
      function MockTSM:new()
        print("Draconic Economy - TSM Disabled");
        setmetatable(self, MockTSM);
        return self;
      end
      function MockTSM.GetCustomPriceValue(db, it)
        return DEFAULT_RUNE_PRICE;
      end
      function MockTSM.FormatMoneyString(amount)
        g = math.floor(amount / 100 / 100);
        s = math.floor((amount - (g * 100 * 100)) / 100);
        c = math.floor((amount - (g * 100 * 100 + s * 100)) / 100);
        return "" .. g .. "|cffffd70ag|r " .. s .. "|cffc7c7cfs|r " .. c .. "|cffeda55fc|r";
      end
      TSM_API = MockTSM:new();
    end
  end
  return TSM_API;
end

function PrintOutput()
  SetCurrentPrice();
  print("===== Draconic Economy =====");
  print("Cumulative Uses: " .. AugmentUses);
  print("Cumulative Savings: " .. FormatMoney(CumulativeSavings) .. " (+" .. FormatMoney(CurrentPrice) .. ")");
  ReusableRunePrice = 1000000000;
  ExpectedUses = math.ceil(ReusableRunePrice / CurrentPrice);
  if AugmentUses ~= 0 then
    ExpectedUses = math.ceil((ReusableRunePrice - CumulativeSavings) / CurrentPrice);
  end
  print("Uses Remaining Until Breakeven: " .. ExpectedUses);
  print("Total Uses At Breakeven: " .. (ExpectedUses + AugmentUses));
  print("Avg Price Expected: " .. FormatMoney(((ExpectedUses * CurrentPrice + CumulativeSavings) / (ExpectedUses + AugmentUses))));
end

function FormatMoney(amount)
  return GetTSM().FormatMoneyString(amount);
end

function SetCurrentPrice()
  CurrentPrice = GetTSM().GetCustomPriceValue("dbregionmarketavg", "i:201325") or DEFAULT_RUNE_PRICE;
end


function IncrementCosts()
  AugmentUses = AugmentUses + 1;
  CumulativeSavings = CumulativeSavings + CurrentPrice;
  LastAugmentUse = time();
end

function SlashCmdList.ECONOMY(msg, editBox)
  PrintOutput();
end

function SlashCmdList.RESETECONOMY(msg, editBox)
  AugmentUses = 0;
  CumulativeSavings = 0;
  LastAugmentUse = 0;
end