function 1_1 {
    # 順次処理：自動インクリメントはJavaScript側で行うため、
    # この関数は呼び出されなくなりました。
    # フォールバック用にデフォルトコードを返す

    $response = @{
        code = 'Write-Host "1OK"'
        nodeName = "順次1"
    }

    return ($response | ConvertTo-Json -Compress)
}
