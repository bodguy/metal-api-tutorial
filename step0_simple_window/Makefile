TARGET		= metal-cpp
CXXFLAGS += -O2 -g -std=c++1z
LFLAGS   += -framework Cocoa -framework QuartzCore
$(TARGET): main.mm
	$(CXX) $(CXXFLAGS) main.mm $(LFLAGS) -o $(TARGET)
clean:
	-$(RM) -rf $(TARGET).dSYM/ $(TARGET)

