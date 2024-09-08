	require "resources.functions.config";

	log = require "resources.functions.log".callflowscheduler

	local Database    = require "resources.functions.database"

	local dbh = Database.new('system');

	--local xml2lua = require("xml2lua")
	--local handler = require("xmlhandler.tree")
	--local parser = xml2lua.parser(handler)
	local SLAXML = require 'slaxdom'

	api = freeswitch.API();
	--------------res = api:execute("sched_del","callflowsched")

	function dump(o)
	   if type(o) == 'table' then
	      local s = '{ '
	      for k,v in pairs(o) do
	         if type(k) ~= 'number' then k = '"'..k..'"' end
	         s = s .. '['..k..'] = ' .. dump(v) .. ','
	      end
	      return s .. '} '
	   else
	      return tostring(o)
	   end
	end


	local sql = 'select "dialplan_xml", "domain_uuid", "dialplan_name" from "v_dialplans" where "app_uuid"=\'4b821450-926b-175a-af93-a03c441818b1\''
	--log.notice("SQL: ".. sql);
	dbh:query(sql, params, function(row)
		dialplan_xml  = row.dialplan_xml;
		domain_uuid   = row.domain_uuid
		dialplan_name = row.dialplan_name
		log.notice("Dialplan name: "..dialplan_name)

		local sql = 'SELECT "call_flow_uuid" FROM "v_call_flows" where "call_flow_name" = :dialplan_name and "domain_uuid" = :domain_uuid'
		local params = {domain_uuid = domain_uuid, dialplan_name = dialplan_name};
		dbh:query(sql, params, function(row)
			call_flow_uuid = row.call_flow_uuid;
			--log.notice(call_flow_uuid)

			--log.notice(dialplan_xml)
			--parser:parse(dialplan_xml)
			local doc = SLAXML:dom(dialplan_xml)

			--log.notice(#handler.root.extension.condition)
			for i, p in pairs(doc.root.kids) do
				if p.name=="condition" and (p.attr["wday"] or p.attr["minute-of-day"]) then
					--local startminute, endminute, startday, endday
					--local startday = 0
					--local endday=0

					if p.attr["wday"] then
						--log.notice("test124: " .. p.attr["wday"])
					    startday, endday = string.match(p.attr["wday"], "(%d+)%-(%d+)")
					    startday    = tonumber(startday)
					    endday      = tonumber(endday)
						--log.notice("timecondition day   : " .. startday.." "..endday);
					end
					if p.attr["minute-of-day"] then
						--log.notice(p.attr["minute-of-day"])
					    startminute, endminute = string.match(p.attr["minute-of-day"], "(%d+)%-(%d+)")
					    startminute = tonumber(startminute)
			    		endminute   = tonumber(endminute)
					end

					log.notice("timecondition day   : " .. startday.." "..endday);
					log.notice("timecondition minute: " .. startminute.." "..endminute);

					--local Timestamp = os.time(os.date("!*t"))
					local Timestamp = os.time()
					local day   = os.date( "%d" , Timestamp )
					local month = os.date( "%m" , Timestamp )
					local year  = os.date( "%Y" , Timestamp )
					local dow   = os.date( "%w" , Timestamp )+1
					local beginningofday = os.time({year = year, month = month, 
				        day = day, hour = '0', min = '0', sec = '0'})
					--log.notice(dow)

					if startday <= dow and dow <= endday then
		
						log.notice("Beginnningofday: "..beginningofday )
						log.notice("Timestamp: "..Timestamp )
						log.notice("Begin:     "..beginningofday+startminute*60)
						log.notice("End:       "..beginningofday+endminute*60)
		
						if Timestamp < beginningofday+startminute*60 then
							log.notice("sched_api "..beginningofday+startminute*60 .." callflowsched set_call_flow.lua "..call_flow_uuid .." true")
							res = api:execute("sched_api",beginningofday+startminute*60 .." callflowsched lua set_call_flow.lua "..call_flow_uuid .." true")
							log.notice("sched_api "..beginningofday+endminute*60 .." callflowsched set_call_flow.lua "..call_flow_uuid .." false")
							res = api:execute("sched_api",beginningofday+endminute*60 .." callflowsched lua set_call_flow.lua "..call_flow_uuid .." false")
						elseif Timestamp >= beginningofday+startminute*60 and Timestamp < beginningofday+endminute*60 then
							log.notice("lua set_call_flow.lua "..call_flow_uuid .." true")
							res = api:execute("lua","set_call_flow.lua "..call_flow_uuid .." true")
							log.notice("sched_api "..beginningofday+endminute*60 .." callflowsched set_call_flow.lua "..call_flow_uuid .." false")
							res = api:execute("sched_api",beginningofday+endminute*60 .." callflowsched lua set_call_flow.lua "..call_flow_uuid .." false")
						else
							log.notice("lua set_call_flow.lua "..call_flow_uuid .." false")
							res = api:execute("lua","set_call_flow.lua "..call_flow_uuid .." false")
						end
					else
						log.notice("lua set_call_flow.lua "..call_flow_uuid .." false")
						res = api:execute("lua","set_call_flow.lua "..call_flow_uuid .." false")
					end

				end
			end
		end);

	end);
