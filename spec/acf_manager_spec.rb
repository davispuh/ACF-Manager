# encoding: UTF-8
require 'spec_helper'

describe 'acf_manager' do
    describe 'normalizePath' do

        it 'should change backslash to forward slashes' do
            normalizePath('C:\\Test\\This\\One').should eq('C:/Test/This/One')
        end

        it 'should replace multiple slashes to single slash' do
            normalizePath('C:\\\\Test\\\\This\\One').should eq('C:/Test/This/One')
        end

        it 'should remove final slash' do
            normalizePath('/home//test/something/').should eq('/home/test/something')
        end

    end

    let(:header) { ['a1', 'b2.num', 'c3'] }
    let(:data) { [['row1_a1', 5, 'row1_c3'], ['row2_a1', 16, 'row2_c3']] }
    let(:dataRow1) { {'a1' => 'row1_a1', 'b2' => {'num' => 5}, 'c3' => 'row1_c3'} }
    let(:dataRow2) { {'a1' => 'row2_a1', 'b2' => {'num' => 16}, 'c3' => 'row2_c3'} }

    describe 'rowToHash' do
        it 'should return hash from row' do
            rowToHash(header, data.first).should eq({'a1' => 'row1_a1', 'b2' => {'num' => 5}, 'c3' => 'row1_c3'})
        end
    end

    describe 'tableToArray' do
        it 'should return built table' do
            tableToArray(header, data).should eq([dataRow1, dataRow2])
        end
    end

    describe 'formatter' do
        it 'should format csv table' do
            formatter(:csv) do |header, data|
                header << 'a'
                header << 'b'
                data << ['v', 'vv']
            end.should eq("a,b\nv,vv\n")
        end

        it 'should format yaml data' do
            formatter(:yml) do |header, data|
                header << 'a'
                header << 'b'
                data << ['v', 'vv']
            end.should eq("---\n- a: v\n  b: vv\n")
        end

        it 'should format json data' do
            formatter(:json) do |header, data|
                header << 'a'
                header << 'b'
                data << ['v', 'vv']
            end.should eq('[{"a":"v","b":"vv"}]')
        end

        it 'should format xml data' do
            formatter(:xml) do |header, data|
                header << 'a'
                header << 'b'
                data << ['v', 'vv']
            end.should eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<result>\n  <entry>\n    <a>v</a>\n    <b>vv</b>\n  </entry>\n</result>")
        end

        it 'should format vdf data' do
            # TODO
        end
    end
end
