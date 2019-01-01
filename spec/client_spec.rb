require_relative 'spec_helper'

describe Signaly::Client do
  describe '#login' do
    let(:client) { described_class.new(config) }

    describe 'with correct credentials' do
      let(:config) do
        Signaly::Config.default.tap do |c|
          c.login = Env.get! 'TEST_LOGIN'
          c.password = Env.get! 'TEST_PASSWORD'
        end
      end

      it 'succeeds' do
        expect do
          client.login
        end.not_to raise_exception
      end
    end

    describe 'with wrong credentials' do
      let(:config) do
        Signaly::Config.default.tap do |c|
          c.login = 'wrong_login'
          c.password = 'wrong_password'
        end
      end

      it 'fails' do
        expect do
          client.login
        end.to raise_exception(RuntimeError, /Login failed/)
      end
    end
  end
end
