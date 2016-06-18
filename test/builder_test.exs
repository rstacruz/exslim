defmodule BuilderTest do
  use ExUnit.Case
  doctest Expug.Builder

  def build(source) do
    with \
      tokens <- Expug.Tokenizer.tokenize(source),
      ast <- Expug.Compiler.compile(tokens) do
      Expug.Builder.build(ast)
    end
  end

  test "build" do
    eex = build("doctype html\ndiv Hello")
    assert eex == %{
      :lines => 2,
      1 => ["<!doctype html>"],
      2 => ["<div>", "Hello", "</div>"]
    }
  end

  test "self-closing img" do
    eex = build("doctype html\nimg")
    assert eex == %{
      :lines => 2,
      1 => ["<!doctype html>"],
      2 => ["<img>"]
    }
  end

  test "self-closing xml" do
    eex = build("doctype xml\nimg")
    assert eex == %{
      :lines => 2,
      1 => ["<?xml version=\"1.0\" encoding=\"utf-8\" ?>"],
      2 => ["<img />"]
    }
  end

  test "single element" do
    eex = build("div")
    assert eex == %{
      :lines => 1,
      1 => ["<div></div>"]
    }
  end

  test "single element with attributes" do
    eex = build("div(id=foo)")
    assert eex == %{
      :lines => 1,
      1 => ["<div id=<%= raw(Expug.Runtime.attr_value(foo)) %>></div>"]
    }
  end

  test "with buffered text" do
    eex = build("div= hola()")
    assert eex == %{
      :lines => 1,
      1 =>["<div>", "<%= hola() %>", "</div>"]
    }
  end

  test "nesting" do
    eex = build("""
    doctype html
    div
      span= @hello
    """)
    assert eex == %{
      :lines => 3,
      1 =>["<!doctype html>"],
      2 =>["<div>"],
      3 =>["<span>", "<%= @hello %>", "</span>", "</div>"]
    }
  end

  test "line comments" do
    eex = build("""
    div
    -# hi
    div
    """)
    assert eex == %{
      :lines => 3,
      1 => ["<div></div>"],
      3 => ["<div></div>"]
    }
  end

  test "line comments, capturing" do
    eex = build("""
    div
    -# hi
      h1
    """)
    assert eex == %{
      :lines => 1,
      1 => ["<div></div>"]
    }
  end

  test "line comments, capturing 2" do
    eex = build("""
    div
    -# hi
      h1
    span
    """)
    assert eex == %{
      :lines => 4,
      1 => ["<div></div>"],
      4 => ["<span></span>"]
    }
  end

  test "indentation magic" do
    eex = build("""
    div
      h1
        span
          | Hello
    """)
    assert eex == %{
      :lines => 4,
      1 => ["<div>"],
      2 => ["<h1>"],
      3 => ["<span>"],
      4 => ["Hello", "</span>", "</h1>", "</div>"]
    }
  end

  test "indentation magic 2" do
    eex = build("""
    div
      h1
        span
          | Hello
    div
    """)
    assert eex == %{
      :lines => 5,
      1 => ["<div>"],
      2 => ["<h1>"],
      3 => ["<span>"],
      4 => ["Hello", "</span>", "</h1>", "</div>"],
      5 => ["<div></div>"]
    }
  end

  test "attr and =" do
    eex = build("""
    div(role="main")= @hello
    """)
    assert eex == %{
      :lines => 1,
      1 => [
        "<div role=<%= raw(Expug.Runtime.attr_value(\"main\")) %>>",
        "<%= @hello %>",
        "</div>"
      ]
    }
  end

  test "lone dot" do
    try do
      build(".")
      flunk "should've thrown something"
    catch err ->
      assert %{
        expected: _,
        position: {1, 1},
        type: :parse_error
      } = err
    end
  end

  @tag :pending
  test "dash" do
    eex = build("-hi")
    assert eex == ""
  end

  @tag :pending
  test "extra space" do
    eex = build("div\n ")
    assert eex == %{
      :lines => 1,
      1 => [
        "<div></div>"
      ]
    }
  end

  @tag :pending
  test "nesting inside" do
    try do
      build("= for item <- @list do\n  div")
      flunk "should've thrown something"
    catch err ->
      assert %{
        expected: _,
        position: {1, 1},
        type: :parse_error
      } = err
    end
  end

end
