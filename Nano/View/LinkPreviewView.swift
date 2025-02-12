//
//  LinkPreviewView.swift
//  Nano
//
//  Created by Richard Henry on 2/15/24.
//

import NanoCore
import NanoKit
import SwiftUI

struct LinkPreviewButton: View {
    @State private var provider: LinkProvider
    @Environment(\.openURL) private var openURL

    init(preview: LinkPreview) {
        _provider = State(wrappedValue: LinkProvider(preview: preview))
    }

    var body: some View {
        Button {
            openURL(provider.url)
        } label: {
            LinkPreviewView(provider: provider)
        }
        .buttonStyle(.plain)
    }
}

struct LinkPreviewView: View {
    var provider: LinkProvider

    var body: some View {
        Group {
            if let title = provider.title, let summary = provider.summary {
                microblog(title: title, summary: summary)
            } else if provider.hasImage {
                cover(image: provider.image)
            } else if let title = provider.title {
                compact(title: title)
            } else {
                empty()
            }
        }
        .task {
            await withDiscardingTaskGroup { group in
                group.addTask {
                    await provider.imageRequest?.fetch()
                }

                group.addTask {
                    await provider.iconRequest?.fetch()
                }
            }
        }
    }

    @ViewBuilder func empty() -> some View {
        HStack(spacing: 3) {
            ZStack {
                ProgressView()
                    .controlSize(.small)
                    .opacity(provider.isFetching ? 1 : 0)

                Image(systemName: "link")
                    .font(.subheadline)
                    .padding(1)
                    .foregroundStyle(.secondary)
                    .opacity(provider.isFetching ? 0 : 1)
            }

            Text(provider.domain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.all, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
        }
    }

    @ViewBuilder func compact(title: String) -> some View {
        head(title: title)
            .lineLimit(3)
            .padding(.vertical, -3)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
            }
    }

    @ViewBuilder func cover(image: Image?) -> some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear

            VStack(alignment: .leading, spacing: 5) {
                if let title = provider.title {
                    Text(title)
                        .lineLimit(3)
                        .shadow(radius: 5)
                        .font(platformValue(iOS: .title3, macOS: .title))
                }

                Text(provider.domain)
                    .shadow(radius: 5)
                    .font(.caption)
                    .fontWeight(.medium)
                    .opacity(0.7)
            }
            .padding()
        }
        .frame(minWidth: 220, maxWidth: 280, minHeight: 0, maxHeight: .infinity)
        .aspectRatio(5 / 3, contentMode: .fit)
        .foregroundStyle(.white)
        .background {
            Color.black

            image?
                .resizable()
                .scaledToFill()

            LinearGradient(
                colors: [.black.opacity(0), .black],
                startPoint: .topLeading,
                endPoint: .bottomLeading
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder func microblog(title: String, summary: String) -> some View {
        VStack(alignment: .leading) {
            Text(summary)
                .lineLimit(16)

            head(title: title)
                .lineLimit(2)
        }
        .padding(.vertical, -3)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
        }
    }

    @ViewBuilder func head(title: String) -> some View {
        HStack {
            provider.icon?
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(provider.domain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    struct WrapperView: View {
        @State var provider: LinkProvider

        init(urlString: String) {
            let request = LinkRequest(url: URL(string: urlString)!)
            provider = LinkProvider(request: request)
        }

        var body: some View {
            LinkPreviewView(provider: provider)
                .task {
                    if case .request(let request) = provider.source {
                        await request.fetch()
                    }
                }
        }
    }

    return ScrollView {
        LazyVStack(spacing: 12) {
            WrapperView(
                urlString:
                    "https://www.newscientist.com/article/2417255-the-existence-of-a-new-kind-of-magnetism-has-been-confirmed/"
            )
            WrapperView(
                urlString:
                    "https://www.latimes.com/california/story/2024-02-16/storms-southern-california-presidents-day-week-rain"
            )
            WrapperView(urlString: "https://twitter.com/catebligh/status/1758198108985389146")
            WrapperView(urlString: "https://www.youtube.com/watch?v=NXpdyAWLDas")
            WrapperView(
                urlString:
                    "https://www.threads.net/@zuck/post/C01LXhDrCAM/?igshid=NTc4MTIwNjQ2YQ%3D%3D"
            )
            WrapperView(urlString: "https://support.apple.com/three-prong-ac-wall-plug-adapter")
            WrapperView(urlString: "https://daringfireball.net/linked/2024/02/16/navalny-rip")
            WrapperView(urlString: "https://mastodon.cc/@tjw/111633986307056524")
        }
        .padding(.horizontal, 50)
    }
}
