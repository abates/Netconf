
require 'test/unit'
require 'netconf/buffer'

class BufferTest < Test::Unit::TestCase
  def setup
    @rd, @wr = IO.pipe
    @buffer = Netconf::NetconfReader.new @rd
  end

  def test_read
    @wr.write("1234567890")
    @wr.close

    reader = @buffer.reader
    s = reader.read(2)

    assert_equal("12", s)

    s = reader.read
    assert_equal("34567890", s)
  end

  def test_readline
    @wr.write("line1\nline2\nline3\n")
    reader = @buffer.reader
    s = reader.readline
    assert_equal("line1\n", s)

    s = reader.readline
    assert_equal("line2\n", s)

    s = reader.readline
    assert_equal("line3\n", s)
  end

  def test_eof
    @wr.write("some text here")
    @wr.close
    reader = @buffer.reader
    assert !reader.eof?

    reader.read(7)
    assert !reader.eof?

    reader.read(7)
    assert reader.eof?
  end

  def test_read_without_tag
    @wr.write("line1\nline2\nline3\n]]>]]>\n")
    s = @buffer.reader.read
    assert_equal "line1\nline2\nline3\n", s
  end

  def test_two_messages_two_reads
    @wr.write("message1\n]]>]]>\nmessage2\n]]>]]>\n")
    reader = @buffer.reader
    s = reader.read
    assert_equal "message1\n", s
    assert reader.eof?

    reader = @buffer.reader
    s = reader.read
    assert_equal "message2\n", s
    assert reader.eof?
  end

  def test_two_messages_with_readline
    @wr.write("m1_l1\nm1_l2\nm1_l3\n]]>]]>\nm2_l1\nm2_l2\nm2_l3\n]]>]]>\n")
    reader = @buffer.reader
    s1 = reader.readline
    s2 = reader.readline
    s3 = reader.readline

    assert_equal("m1_l1\n", s1)
    assert_equal("m1_l2\n", s2)
    assert_equal("m1_l3\n", s3)
    assert_raise(EOFError) do
      reader.readline
    end
    assert reader.eof?

    reader = @buffer.reader
    s1 = reader.readline
    s2 = reader.readline
    s3 = reader.readline

    assert_equal("m2_l1\n", s1)
    assert_equal("m2_l2\n", s2)
    assert_equal("m2_l3\n", s3)
    assert_raise(EOFError) do
      reader.readline
    end
    assert reader.eof?
  end
end
