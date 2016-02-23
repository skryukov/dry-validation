RSpec.describe Schema, 'using high-level rules' do
  subject(:validate) { schema.new }

  context 'composing rules' do
    let(:schema) do
      Class.new(Schema) do
        def self.messages
          Messages.default.merge(
            en: { errors: { destiny: 'you must select either red or blue' } }
          )
        end

        optional(:red).maybe
        optional(:blue).maybe

        rule(:destiny) { value(:red).filled? | value(:blue).filled? }
      end
    end

    it 'passes when only red is filled' do
      expect(validate.(red: '1')).to be_success
    end

    it 'fails when red and blue are not filled ' do
      expect(validate.(red: nil, blue: nil).messages[:destiny]).to eql(
        ['you must select either red or blue']
      )
    end
  end

  context 'composing specific predicates' do
    let(:schema) do
      Class.new(Schema) do
        def self.messages
          Messages.default.merge(
            en: {
              errors: {
                email_presence: 'email must be present when login is set to true',
                email_absence: 'email must not be present when login is set to false'
              }
            }
          )
        end

        key(:login).required(:bool?)
        key(:email).maybe

        rule(:email_presence) { value(:login).true?.then(value(:email).filled?) }

        rule(:email_absence) { value(:login).false?.then(value(:email).none?) }
      end
    end

    it 'passes when login is false and email is nil' do
      expect(validate.(login: false, email: nil)).to be_success
    end

    it 'fails when login is false and email is present' do
      expect(validate.(login: false, email: 'jane@doe').messages).to eql(
        email_absence: ['email must not be present when login is set to false']
      )
    end

    it 'passes when login is true and email is present' do
      expect(validate.(login: true, email: 'jane@doe')).to be_success
    end

    it 'fails when login is true and email is not present' do
      expect(validate.(login: true, email: nil).messages).to eql(
        email_presence: ['email must be present when login is set to true']
      )
    end
  end
end
