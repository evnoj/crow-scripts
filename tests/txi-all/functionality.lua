ii.txi.event = function(e, data)
  if e.name == 'all' then
    for i, v in ipairs(data) do print(i, v) end
  end
end

poller = clock.run(function()
    while true do
        clock.sleep(0.1)
        ii.txi.get('all')
    end
end)

