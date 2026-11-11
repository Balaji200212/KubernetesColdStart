
# ==========================================
# REAL-TIME PARALLEL LOAD TEST
# ==========================================

$numberOfRequests = 1000
$url = "http://localhost:8081/api/load?seconds=30"

Add-Type -AssemblyName System.Net.Http

# Allow many simultaneous HTTP connections
[System.Net.ServicePointManager]::DefaultConnectionLimit = 200

$handler = New-Object System.Net.Http.HttpClientHandler
$client = New-Object System.Net.Http.HttpClient($handler)

$client.Timeout = [TimeSpan]::FromSeconds(90)

$pending = [System.Collections.ArrayList]::new()
$results = [System.Collections.ArrayList]::new()

Write-Host "`nPreparing $numberOfRequests requests..." -ForegroundColor Yellow

# Start all requests without waiting for previous responses
for ($i = 1; $i -le $numberOfRequests; $i++) {

    $timer = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $task = $client.GetAsync($url)

        [void]$pending.Add([PSCustomObject]@{
            Id = $i
            Task = $task
            Timer = $timer
        })
    }
    catch {
        $timer.Stop()

        [void]$results.Add([PSCustomObject]@{
            RequestId = $i
            Status = $null
            Result = "FAILURE"
            Time = 0
            Response = ""
            Error = $_.Exception.Message
        })
    }
}

Write-Host "All $numberOfRequests requests dispatched!" -ForegroundColor Green
Write-Host "Waiting for individual responses...`n" -ForegroundColor Cyan

# Print each result as soon as that request completes
while ($pending.Count -gt 0) {

    for ($i = $pending.Count - 1; $i -ge 0; $i--) {

        $item = $pending[$i]

        if ($item.Task.IsCompleted) {

            $item.Timer.Stop()

            $status = $null
            $body = ""
            $errorMessage = ""
            $result = "FAILURE"

            try {
                if ($item.Task.IsFaulted) {
                    throw $item.Task.Exception.GetBaseException()
                }

                if ($item.Task.IsCanceled) {
                    throw "Request was cancelled or timed out"
                }

                $response = $item.Task.Result
                $status = [int]$response.StatusCode

                $body = $response.Content.ReadAsStringAsync().
                    GetAwaiter().GetResult()

                if ($status -ge 200 -and $status -lt 300) {
                    $result = "SUCCESS"
                }
                else {
                    $result = "FAILURE"
                    $errorMessage = "HTTP $status"
                }

                $response.Dispose()
            }
            catch {
                $errorMessage = $_.Exception.Message
            }

            $record = [PSCustomObject]@{
                RequestId = $item.Id
                Status = $status
                Result = $result
                Time = [math]::Round($item.Timer.Elapsed.TotalSeconds, 2)
                Response = $body
                Error = $errorMessage
            }

            [void]$results.Add($record)

            $color = if ($result -eq "SUCCESS") { "Green" } else { "Red" }

            Write-Host "Request $($item.Id) | HTTP $status | $result | $($record.Time)s" -ForegroundColor $color

            if ($body) {
                Write-Host "Response: $body"
            }
            elseif ($errorMessage) {
                Write-Host "Error: $errorMessage"
            }

            $pending.RemoveAt($i)
        }
    }

    Start-Sleep -Milliseconds 100
}

$client.Dispose()
$handler.Dispose()

# ==========================================
# FINAL SUMMARY
# ==========================================

$success = @($results | Where-Object { $_.Result -eq "SUCCESS" })
$failure = @($results | Where-Object { $_.Result -eq "FAILURE" })

Write-Host "`n========== FINAL SUMMARY ==========" -ForegroundColor Yellow

Write-Host "Total Requests : $($results.Count)"
Write-Host "Successful     : $($success.Count)" -ForegroundColor Green
Write-Host "Failed         : $($failure.Count)" -ForegroundColor Red

Write-Host "`n========== ALL REQUEST RESULTS =========="

$results | Sort-Object RequestId |
    Format-Table RequestId, Status, Result, Time -AutoSize
