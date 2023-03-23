Describe "Integration Tests" -Tag "IntegrationTests" {
    It "gets a bunch of suppliers" {
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers
        ($results).Count | Should -BeGreaterThan 10
        ($results | Where-Object supplier_id -eq '2').country | Should -Be "USA"
    }
    
    It "gets a specific supplier" {
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers/2
        $results.company_name | Should -Be "New Orleans Cajun Delights"
    }

    It "adds a supplier" {
        $body = @{
            supplier_id   = "10000"
            address       = "100 Rue du Nord"
            city          = "Paris"
            company_name  = "10000o Enterprises"
            contact_name  = "Kitty LeMaire"
            contact_title = "Sales Representative"
            country       = "France"
            fax           = "030-0076545"
            phone         = "030-0074321"
            postal_code   = "12209"
            region        = $null
        } | ConvertTo-Json

        { Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers -Method POST -Body $body -ErrorAction Stop } | Should -Not -Throw

        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers/10000
        $results.supplier_id | Should -BeExactly "10000"
    }

    It "updates a supplier" {
        $body = @{
            contact_name   = 'Kitty Cankles'
            contact_title  = 'Senior Sales Representative'
        } | ConvertTo-Json

        { Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers/10000 -Method PATCH -Body $body -ErrorAction Stop } | Should -Not -Throw

        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers/10000
        $results.contact_name | Should -BeExactly "Kitty Cankles"
    }

    It "deletes one supplier and does not modify any others" {
        Invoke-RestMethod -Method DELETE -Uri http://localhost:7071/v1/suppliers/10000
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers/10000
        $results | Should -BeNullOrEmpty
        
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/suppliers/2
        $results.supplier_id | Should -Be 2
        $results.postal_code | Should -Be 70117
    }

}