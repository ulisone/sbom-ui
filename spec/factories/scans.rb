FactoryBot.define do
  factory :scan do
    project { nil }
    status { "MyString" }
    sbom_format { "MyString" }
    sbom_content { "" }
    scanned_at { "2026-01-12 11:51:54" }
    file_name { "MyString" }
    ecosystem { "MyString" }
  end
end
