require 'api_spec_helper'
require 'cancan/matchers'

describe 'ChatMessageAbility' do
  let(:user) { Factory(:user) }
  subject { Api::Ability.new(user) }

  context "when participating as sender" do
    let(:chat_message) do
      Factory(:chat_message, :user => user)
    end

    it "should be able to read" do
      subject.should be_able_to :read, chat_message
    end
  end

  context "when participating as receiver" do
    let(:chat_message) do
      Factory(:chat_message, :contact => user)
    end

    it "should be able to read" do
      subject.should be_able_to :read, chat_message
    end
  end

  context "when not participating" do
    let(:chat_message) { Factory(:chat_message) }

    it "should not be able to read" do
      subject.should_not be_able_to :read, chat_message
    end
  end

end