import SwiftUI

public enum SegueType {
    case push,
         modal,
         popover(PopoverAttachmentAnchor, Edge),
         `switch`(AnyTransition?, Animation?)
}

public struct Segue<Destination, Selection>: ViewModifier
where Destination : View, Selection : Hashable {
    let type: SegueType
    let tag: Selection
    @Binding var selection: Selection?
    @ViewBuilder let destination: () -> Destination
    
    public init(type: SegueType,
                tag: Selection,
                selection: Binding<Selection?>,
                @ViewBuilder destination: @escaping () -> Destination) {
        self.type = type
        self.tag = tag
        _selection = selection
        self.destination = destination
    }
    
    public func body(content: Content) -> some View {
        switch type {
        case .push:
            pushSegue(content)
        case .modal:
            modalSegue(content)
        case let .popover(anchor, arrowEdge):
            popoverSegue(content, anchor: anchor, arrowEdge: arrowEdge)
        case let .switch(transition, animation):
          switchSegue(content, transition: transition, animation: animation)
        }
    }
    
    @ViewBuilder private func pushSegue(_ content: Content) -> some View {
        ZStack {
            content
            // By default, NavigationLink destinations should be lazily loaded, but that
            // apparently isn't always the case. This check prevents destinations from
            // being loaded ahead of time.
            if selection == tag {
              NavigationLink(tag: tag,
                             selection: $selection,
                             destination: destination) {
                  EmptyView()
              }
              .isDetailLink(false)
            } else {
              EmptyView();
            }
        }
    }
    
    @ViewBuilder private func modalSegue(_ content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content
                .fullScreenCover(isPresented: Binding(get: {
                    selection == tag
                }, set: { _ in
                    selection = nil
                }),
                                 onDismiss: nil,
                                 content: destination)
        } else {
            content
                .fullScreenCoverBoolCompat(isPresented: Binding(get: {
                    selection == tag
                }, set: { _ in
                    selection = nil
                }),
                                           content: destination)
        }
    }
    
    @ViewBuilder private func popoverSegue(_ content: Content,
                                           anchor: PopoverAttachmentAnchor,
                                           arrowEdge: Edge) -> some View {
        content
            .popover(isPresented: Binding(get: {
                selection == tag
            }, set: { _ in
                selection = nil
            }),
                     attachmentAnchor: anchor,
                     arrowEdge: arrowEdge,
                     content: destination)
    }
  
  @ViewBuilder private func switchSegue(_ content: Content,
                                        transition: AnyTransition?,
                                        animation: Animation?) -> some View {
    ZStack {
      if selection == tag {
        destination()
          .transition(transition ?? .slide)
      } else {
        content
          .transition(transition ?? .slide)
      }
    }
    .animation(animation)
  }
}

public extension View {
    func segue<Destination, Selection>(_ type: SegueType,
                                       tag: Selection,
                                       selection: Binding<Selection?>,
                                       @ViewBuilder destination: @escaping () -> Destination) -> some View
    where Destination : View, Selection : Hashable {
        self.modifier(Segue(type: type,
                            tag: tag,
                            selection: selection,
                            destination: destination))
    }
}

public struct Segues<Destination, Selection>: ViewModifier
where Destination : View, Selection : Identifiable, Selection : CaseIterable, Selection : Hashable {
    let type: SegueType
    @Binding var selection: Selection?
    @ViewBuilder let destination: (Selection) -> Destination
    
    public init(type: SegueType,
                selection: Binding<Selection?>,
                @ViewBuilder destination: @escaping (Selection) -> Destination) {
        self.type = type
        _selection = selection
        self.destination = destination
    }
    
    public func body(content: Content) -> some View {
        switch type {
        case .push:
            pushSegue(content)
        case .modal:
            modalSegue(content)
        case let .popover(anchor, arrowEdge):
            popoverSegue(content, anchor: anchor, arrowEdge: arrowEdge)
        case let .switch(transition, animation):
          switchSegue(content, transition: transition, animation: animation)
        }
    }
    
    @ViewBuilder private func pushSegue(_ content: Content) -> some View {
        ZStack {
            content
            ForEach(Array(Selection.allCases)) { tag in
                NavigationLink(tag: tag,
                               selection: $selection,
                               destination: { destination(tag) }) {
                    EmptyView()
                }
                .isDetailLink(false)
            }
        }
    }
    
    @ViewBuilder private func modalSegue(_ content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content
                .fullScreenCover(item: $selection,
                                 onDismiss: nil,
                                 content: destination)
        } else {
            content
                .fullScreenCoverCompat(item: $selection,
                                       content: destination)
        }
    }
    
    @ViewBuilder private func popoverSegue(_ content: Content,
                                           anchor: PopoverAttachmentAnchor,
                                           arrowEdge: Edge) -> some View {
        content
            .popover(item: $selection,
                     attachmentAnchor: anchor,
                     arrowEdge: arrowEdge,
                     content: destination)
    }
  
  @ViewBuilder private func switchSegue(_ content: Content,
                                        transition: AnyTransition?,
                                        animation: Animation?) -> some View {
    ZStack {
      if let tag = selection {
        destination(tag)
          .transition(transition ?? .slide)
      } else {
        content
          .transition(transition ?? .slide)
      }
    }
    .animation(animation)
  }
}

public extension View {
    func segues<Destination, Selection>(_ type: SegueType,
                                        selection: Binding<Selection?>,
                                        @ViewBuilder destination: @escaping (Selection) -> Destination) -> some View
    where Destination : View, Selection : Identifiable, Selection: CaseIterable, Selection : Hashable {
        self.modifier(Segues(type: type,
                             selection: selection,
                             destination: destination))
    }
}

struct FullScreenCoverCompat<CoverContent: View, Item: Identifiable>: ViewModifier {
  @Binding var item: Item?
  let content: (Item) -> CoverContent

  func body(content: Content) -> some View {
    GeometryReader { geo in
      ZStack {
        // this color makes sure that its enclosing ZStack
        // (and the GeometryReader) fill the entire screen,
        // allowing to know its full height
        Color.clear
        content
      ZStack {
        // the color is here for the cover to fill
        // the entire screen regardless of its content
        Color.white
        if let item = item {
            self.content(item)
        }
      }
      .offset(y: (item != nil) ? 0 : geo.size.height)
      // feel free to play around with the animation speeds!
      .animation(.spring())
      }
    }
  }
}

extension View {
    func fullScreenCoverCompat<Content: View, Item: Identifiable>(item: Binding<Item?>,
                                                                  content: @escaping (Item) -> Content) -> some View {
    self.modifier(FullScreenCoverCompat(item: item,
                                        content: content))
  }
}

struct FullScreenCoverBoolCompat<CoverContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  let content: () -> CoverContent

  func body(content: Content) -> some View {
    GeometryReader { geo in
      ZStack {
        // this color makes sure that its enclosing ZStack
        // (and the GeometryReader) fill the entire screen,
        // allowing to know its full height
        Color.clear
        content
        ZStack {
          // the color is here for the cover to fill
          // the entire screen regardless of its content
          Color.white
          self.content()
        }
        .offset(y: isPresented ? 0 : geo.size.height)
        // feel free to play around with the animation speeds!
        .animation(.spring())
      }
    }
  }
}

extension View {
  func fullScreenCoverBoolCompat<Content: View>(isPresented: Binding<Bool>,
                                            content: @escaping () -> Content) -> some View {
    self.modifier(FullScreenCoverBoolCompat(isPresented: isPresented,
                                            content: content))
  }
}

struct PushSegueTest: View {
    @State private var route: Route? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Go to A") {
                    route = .a
                }
                Button("Go to B") {
                    route = .b
                }
                Button("Go to C") {
                    route = .c
                }
            }
            .segues(.push, selection: $route) { route in
                switch route {
                case .a:
                    Text("A")
                case .b:
                    Text("B")
                case .c:
                    Text("C")
                }
            }
        }
    }
    
    enum Route: Identifiable, CaseIterable, Hashable {
        case a, b, c
        
        var id: String {
            "\(self)"
        }
    }
}

struct PushSegueTest_Preview: PreviewProvider {
    static var previews: some View {
        PushSegueTest()
    }
}

struct ModalSegueTest: View {
    @State private var route: Route? = nil
    
    var body: some View {
        VStack {
            Button("Go to A") {
                route = .a
            }
            Button("Go to B") {
                route = .b
            }
            Button("Go to C") {
                route = .c
            }
        }
        .segues(.modal, selection: $route) { route in
            switch route {
            case .a:
                Button("A") {
                    self.route = nil
                }
            case .b:
                Button("B") {
                    self.route = nil
                }
            case .c:
                Button("C") {
                    self.route = nil
                }
            }
        }
    }
    
    enum Route: Identifiable, CaseIterable, Hashable {
        case a, b, c
        
        var id: String {
            "\(self)"
        }
    }
}

struct ModalSegueTest_Preview: PreviewProvider {
    static var previews: some View {
        ModalSegueTest()
    }
}

struct PopoverSegueTest: View {
    @State private var route: Route? = nil
    
    var body: some View {
        VStack {
            Button("Go to A") {
                route = .a
            }
            Button("Go to B") {
                route = .b
            }
            Button("Go to C") {
                route = .c
            }
        }
        .segues(.popover(.rect(.bounds), .top), selection: $route) { route in
            switch route {
            case .a:
                Button("A") {
                    self.route = nil
                }
            case .b:
                Button("B") {
                    self.route = nil
                }
            case .c:
                Button("C") {
                    self.route = nil
                }
            }
        }
    }
    
    enum Route: Identifiable, CaseIterable, Hashable {
        case a, b, c
        
        var id: String {
            "\(self)"
        }
    }
}

struct PopoverSegueTest_Preview: PreviewProvider {
    static var previews: some View {
        PopoverSegueTest()
    }
}

struct SwitchSegueTest: View {
    @State private var route: Route? = nil
    
    var body: some View {
        VStack {
            Button("Go to A") {
              route = .a
            }
            Button("Go to B") {
                route = .b
            }
            Button("Go to C") {
                route = .c
            }
        }
        .segues(.switch(.move(edge: .bottom), .easeInOut), selection: $route) { route in
            switch route {
            case .a:
                Button("A") {
                    self.route = nil
                }
            case .b:
                Button("B") {
                    self.route = nil
                }
            case .c:
                Button("C") {
                    self.route = nil
                }
            }
        }
    }
    
    enum Route: Identifiable, CaseIterable, Hashable {
        case a, b, c
        
        var id: String {
            "\(self)"
        }
    }
}

struct SwitchSegueTest_Preview: PreviewProvider {
    static var previews: some View {
        SwitchSegueTest()
    }
}

struct MixedSegueTest: View {
    @State private var route: Route? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Push") {
                    route = .push
                }
                Button("Modal") {
                    route = .modal
                }
                Button("Popover") {
                    route = .popover
                }
            }
            .navigationBarTitle("SwiftUI Segues", displayMode: .inline)
            .segue(.push, tag: .push, selection: $route) {
                Text("Welcome to Push")
            }
            .segue(.modal, tag: .modal, selection: $route) {
                Button("Welcome to modal") {
                    route = nil
                }
            }
            .segue(.popover(.rect(.bounds), .top), tag: .popover, selection: $route) {
                Text("Welcome to Popover")
            }
        }
    }
    
    enum Route: Hashable {
        case push, modal, popover
    }
}

struct MixedSegueTest_Preview: PreviewProvider {
    static var previews: some View {
        MixedSegueTest()
    }
}
