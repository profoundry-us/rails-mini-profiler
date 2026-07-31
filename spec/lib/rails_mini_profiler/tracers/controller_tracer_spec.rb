# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

module RailsMiniProfiler
  module Tracers
    RSpec.describe ControllerTracer do
      describe 'trace' do
        let(:payload) { { view_runtime: 10, db_runtime: 5, ignore: 100 } }
        let(:event) { OpenStruct.new(payload: payload) }

        subject { ControllerTracer.new(event) }

        it('should remove payload fields') do
          trace = subject.trace
          expected = { view_runtime: 10, db_runtime: 5 }
          expect(trace.payload).to eq(expected)
        end

        context 'with blank values' do
          let(:payload) { { view_runtime: '', db_runtime: 5 } }

          it('should remove blank values') do
            trace = subject.trace
            expected = { db_runtime: 5 }
            expect(trace.payload).to eq(expected)
          end
        end

        context 'with numbers' do
          let(:payload) { { view_runtime: 10.105 } }

          it('should round to two digits') do
            trace = subject.trace
            expected = { view_runtime: 10.11 }
            expect(trace.payload).to eq(expected)
          end
        end

        context 'with request details' do
          let(:payload) do
            {
              controller: 'MoviesController',
              action: 'index',
              format: :html,
              method: 'GET',
              status: 200,
              params: { 'controller' => 'movies', 'action' => 'index', 'page' => '2' },
              view_runtime: 10
            }
          end

          it('keeps controller, action, format, method, status and filtered params') do
            trace = subject.trace
            expect(trace.payload).to eq(
              controller: 'MoviesController',
              action: 'index',
              format: 'html',
              method: 'GET',
              status: 200,
              params: { 'page' => '2' },
              view_runtime: 10
            )
          end
        end

        context 'with non-serializable param values' do
          let(:payload) do
            upload = OpenStruct.new(to_s: '#<UploadedFile poster.png>')
            { params: { 'controller' => 'movies', 'action' => 'create', 'poster' => upload, 'nested' => { 'n' => 1 } } }
          end

          it('stringifies anything that is not a basic type') do
            trace = subject.trace
            expect(trace.payload[:params]).to eq('poster' => '#<UploadedFile poster.png>', 'nested' => { 'n' => 1 })
          end
        end
      end
    end
  end
end
