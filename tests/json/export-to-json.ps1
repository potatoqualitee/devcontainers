$PSDefaultParameterValues["Invoke-PostgresQuery:Connection"] = Connect-Postgres -ConnectionString "host=localhost;port=5432;database=db;user id=dbuser; password=BB723117-3Edc-4629-94ba-D7d3143C0500!;"

$tables = @{
    order_details          = "order_id"
    orders                 = "order_id"
    customers              = "order_id"
    products               = "order_id"
    suppliers              = "order_id"
    employees              = "order_id"
}


New-Item -Type Directory -Path ./tests/json -ErrorAction Ignore
foreach ($key in $tables.Keys) {
    New-Item -Type Directory -Path ./tests/json/$key -ErrorAction Ignore
}

Invoke-PostgresQuery -Query "select * from orders" | ForEach-Object {
    $id = (New-Guid).ToString()
    $PSItem | Add-Member -Passthru -NotePropertyName id -NotePropertyValue $id |
        ConvertTo-Json -EnumsAsStrings | Out-File -Path ./tests/json/orders/$id.json
}

Invoke-PostgresQuery -Query "select d.* from order_details d join orders o on d.order_id = o.order_id" | ForEach-Object {
    $id = (New-Guid).ToString()
    $PSItem | Add-Member -Passthru -NotePropertyName id -NotePropertyValue $id |
    ConvertTo-Json -EnumsAsStrings | Out-File -Path ./tests/json/order_details/$id.json
}

Invoke-PostgresQuery -Query "select p.*, o.order_id from products p join order_details d on
p.product_id = d.product_id join orders o on d.order_id = o.order_id" | ForEach-Object {
    $id = (New-Guid).ToString()
    $PSItem | Add-Member -Passthru -NotePropertyName id -NotePropertyValue $id |
        ConvertTo-Json -EnumsAsStrings | Out-File -Path ./tests/json/products/$id.json
}

Invoke-PostgresQuery -Query "select c.*, o.order_id from customers c join orders o on c.customer_id = o.customer_id" | ForEach-Object {
    $id = (New-Guid).ToString()
    $PSItem | Add-Member -Passthru -NotePropertyName id -NotePropertyValue $id |
        ConvertTo-Json -EnumsAsStrings | Out-File -Path ./tests/json/customers/$id.json
}

Invoke-PostgresQuery -Query "select e.*, o.order_id from employees e join orders o on e.employee_id = o.employee_id" | ForEach-Object {
    $id = (New-Guid).ToString()
    $PSItem | Add-Member -Passthru -NotePropertyName id -NotePropertyValue $id |
        ConvertTo-Json -EnumsAsStrings | Out-File -Path ./tests/json/employees/$id.json
}

Invoke-PostgresQuery -Query "select s.*, o.order_id from suppliers s join products p on
s.supplier_id = p.product_id join order_details d on p.product_id = d.product_id
join orders o on d.order_id = o.order_id" | ForEach-Object {
    $id = (New-Guid).ToString()
    $PSItem | Add-Member -Passthru -NotePropertyName id -NotePropertyValue $id |
        ConvertTo-Json -EnumsAsStrings | Out-File -Path ./tests/json/suppliers/$id.json
}
