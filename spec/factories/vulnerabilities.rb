FactoryBot.define do
  factory :vulnerability do
    scan { nil }
    cve_id { "MyString" }
    severity { "MyString" }
    package_name { "MyString" }
    package_version { "MyString" }
    title { "MyString" }
    description { "MyText" }
    fixed_version { "MyString" }
    cvss_score { 1.5 }
    references { "" }
  end
end
