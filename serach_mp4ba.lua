local curl = require "lcurl.safe"

script_info = {
	["title"] = "MP4吧",
	["description"] = "http://mp4ba.cc/; 搜索框输入:config设置是否过滤失效链接",
	["version"] = "0.0.7",
}


function request(url,header)
	local r = ""
	local c = curl.easy{
		url = url,
		httpheader = header,
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
		followlocation = 1,
		timeout = 15,
		proxy = pd.getProxy(),
		writefunction = function(buffer)
			r = r .. buffer
			return #buffer
		end,
	}
	local _, e = c:perform()
	c:close()
	return r
end

function onSearch(key, page)

	if key == ":config" and page == 1 then
		return setConfig()
	end

	local result = {}
	-- 搜索电视剧
	result = search_movie(key,page,"6",result)
	-- 搜索电影
	result = search_movie(key,page,"1",result)

	return result


end

function search_movie(key, page,modelid, result)
	local header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
	}

	local data = request("http://mp4ba.cc/search/index/init/modelid/".. modelid .."/q/" .. pd.urlEncode(key) .. "/page/" .. page .. ".html" , header)
	local start = 1

	while true do

		local start_position, end_position, href, title,description, pub_time = string.find(data,'<div class="sousuo">.-<b><a href="(.-)" target="_blank">(.-)</a></b>.-target="_blank">(.-)</a></p>.-<span>(.-)</span>',start)

		if href == nil then
			break
		end

		local tooltip = string.gsub(title, "<span style='color:#f60;'>(.-)</span>", "%1")

		title = string.gsub(title, "<span style='color:#f60;'>(.-)</span>", "{c #ff0000}%1{/c}")

		description = string.gsub(description, "<span style='color:#f60;'>(.-)</span>", "%1")
		local img
		if modelid == "6" then
			img = "FolderType.png"
		else
			img = "VideoType.png"
		end

		local filtration = pd.getConfig("mp4吧","filtration")
		if filtration == "yes" then
			url = getUrl(href)
		else
			url = nil
		end


		table.insert(result, {["href"] = href, ["url"] = url, ["title"] = title,["showhtml"] = "true", ["tooltip"] = tooltip, ["time"] = pub_time, ["description"] = description, ["image"] = "icon/FileType/Middle/"..img, ["icon_size"] = "32,32", ["check_url"] = "true" })

		start = end_position + 1

	end

	return result
end

function onItemClick(item)

	if item.isConfig then
		if item.isSel == "1" then
			return ACT_NULL
		else
			pd.setConfig("mp4吧", item.key, item.val)
			return ACT_MESSAGE, "设置成功! (请手动刷新页面)"
		end
	end


	local url = item.url or getUrl(item.href)

	if url  then
		return ACT_SHARELINK, url
		--return ACT_MESSAGE, url
	else
		return ACT_MESSAGE, "该资源未上传百度云或获取资源失败"
	end

end

function getUrl(href)
	local header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
	}

	local ret = request(href,header)

	local _, __, url, pwd = string.find(ret,'cloud.-<a href="(.-)".-百度云地址.-<p>提取码：(.-)</p>',1)

	if url ~= nil and (string.find(url,"pan.baidu.com")) then
		url = url .. " " .. pwd
	else
		url = nil
	end

	return url
end

function setConfig()
	local config = {}
	local filtration = pd.getConfig("mp4吧","filtration")
	table.insert(config, {["title"] = "过滤失效链接", ["enabled"] = "false"})
	table.insert(config, createConfigItem("不过滤失效链接", "filtration", "no", #filtration == 0 or filtration == "no"))
	table.insert(config, createConfigItem("过滤失效链接", "filtration", "yes",  filtration == "yes"))

	return config
end

function createConfigItem(title, key, val, isSel)
	local item = {}
	item.title = title
	item.key = key
	item.val = val
	item.icon_size = "14,14"
	item.isConfig = "1"
	if isSel then
		item.image = "option/selected.png"
		item.isSel = "1"
	else
		item.image = "option/normal.png"
		item.isSel = "0"
	end
	return item
end