if getgenv().hi == nil then getgenv().hi = false end
getgenv().hi = not getgenv().hi

setfflag('NextGenReplicatorEnabledWrite4', tostring(hi))
