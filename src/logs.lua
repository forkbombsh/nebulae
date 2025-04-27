local logs = {}

function logs.log(message)
    table.insert(logs.logsTable, { text = message })
end

function logs.config(logsTable)
    logs.logsTable = logsTable
end

return logs
