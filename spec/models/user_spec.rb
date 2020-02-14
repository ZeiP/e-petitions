require 'rails_helper'

RSpec.describe User, type: :model do
  context 'methods' do
    context '#full_name' do
      context 'with null firstname' do

        let(:user) { FactoryBot.build(:user, lastname: 'lastname') }

        it 'defaults to nil name' do
          expect(user.full_name).to eq('lastname')
        end
      end

      context 'with null lastname' do
        let(:user) { FactoryBot.build(:user, firstname: 'firstname') }

        it 'defaults to nil name' do
          expect(user.full_name).to eq('firstname')
        end
      end

      context 'with null names' do
        let(:user) { FactoryBot.build(:user) }

        it 'defaults to username' do
          expect(user.full_name).to eq(user.username)
        end
      end
    end
  end
end