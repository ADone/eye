require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl notify" do
  it "integration" do
    conf = <<-E
      Eye.config do
        mail :host => "mx.some.host.ru", :port => 25

        contact :vasya, :mail, "vasya@mail.ru"
        contact :petya, :mail, "petya@mail.ru", :port => 1111

        contact_group :idiots do
          contact :idiot1, :mail, "idiot1@mail.ru"
          contact :idiot2, :mail, "idiot1@mail.ru", :port => 1111
        end
      end

      Eye.application :bla do
        notify :vasya
        notify :idiots, :crit

        group :gr1 do
          notify :petya
          notify :idiot1, :warn
        end
      end
    E
    res = Eye::Dsl.parse(conf)

    res.should == {
      :applications => {
        "bla"=>{:name=>"bla", 
          :notify=>{"vasya"=>:crit, "idiots"=>:crit}, 
          :groups=>{"gr1"=>{:name=>"gr1", 
            :notify=>{"vasya"=>:crit, "idiots"=>:crit, "petya"=>:crit, "idiot1"=>:warn}, :application=>"bla", :processes=>{}}}}},
      :config => {
        :mail=>{:host=>"mx.some.host.ru", :port => 25, :type => :mail}, 
        :contacts=>{
          "vasya"=>{:name=>"vasya", :type=>:mail, :contact=>"vasya@mail.ru", :opts=>{}}, 
          "petya"=>{:name=>"petya", :type=>:mail, :contact=>"petya@mail.ru", :opts=>{:port=>1111}}, 
          'idiots'=>[{:name=>"idiot1", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{}}, {:name=>"idiot2", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{:port=>1111}}], 
          "idiot1"=>{:name=>"idiot1", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{}}, 
          "idiot2"=>{:name=>"idiot2", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{:port=>1111}}}}}
  end

  it "valid contact type" do
    conf = <<-E
      Eye.config do
        contact :vasya, :mail, "vasya@mail.ru", :port => 25, :host => "localhost"
      end
    E
    Eye::Dsl.parse(conf)[:config].should == {:contacts=>{
      "vasya"=>{:name=>"vasya", :type=>:mail, :contact=>"vasya@mail.ru", :opts=>{:port => 25, :host => "localhost"}}}}
  end

  it "raise on unknown contact type" do
    conf = <<-E
      Eye.config do
        contact :vasya, :dddd, "vasya@mail.ru"
      end
    E
    expect{ Eye::Dsl.parse(conf) }.to raise_error(Eye::Dsl::Error)
  end

  it "raise on unknown additional_options" do
    conf = <<-E
      Eye.config do
        contact :vasya, :mail, "vasya@mail.ru", :bla => 1
      end
    E
    expect{ Eye::Dsl.parse(conf) }.to raise_error(Eye::Checker::Validation::Error)
  end

  it "set notify inherited" do
    conf = <<-E
      Eye.app :bla do
        notify :vasya

        group :bla do
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name=>"bla", 
        :notify=>{"vasya"=>:crit}, 
        :groups=>{"bla"=>{:name=>"bla", 
          :notify=>{"vasya"=>:crit}, :application=>"bla", :processes=>{}}}}}
  end

  it "clear notify with nonotify" do
    conf = <<-E
      Eye.app :bla do
        notify :vasya

        group :bla do
          nonotify :vasya
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name=>"bla", 
        :notify=>{"vasya"=>:crit}, 
        :groups=>{"bla"=>{:name=>"bla", :notify=>{}, :application=>"bla", :processes=>{}}}}}
  end
end