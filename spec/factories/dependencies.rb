FactoryBot.define do
  factory :dependency do
    scan { nil }
    name { "MyString" }
    version { "MyString" }
    ecosystem { "MyString" }
    purl { "MyString" }
    license { "MyString" }
  end
end
